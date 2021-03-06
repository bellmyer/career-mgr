require 'digest/md5'
require 'csv'
require 'fellow_user_matcher'
require 'taggable'
require 'open-uri'

class Fellow < ApplicationRecord
  acts_as_paranoid
  include Taggable

  has_one :contact, as: :contactable, dependent: :destroy
  accepts_nested_attributes_for :contact
  
  has_one :access_token, as: :owner
  
  has_many_attached :resumes
  
  has_many :cohort_fellows, dependent: :destroy
  has_many :cohorts, through: :cohort_fellows
  has_many :fellow_opportunities, dependent: :destroy
  has_many :career_steps
  
  has_and_belongs_to_many :opportunity_types

  taggable :industries, :interests, :majors, :industry_interests, :metros
  
  belongs_to :employment_status
  belongs_to :user, optional: true
  
  validates :first_name, :last_name, presence: true
  
  validates :graduation_semester, inclusion: {in: (Course::VALID_SEMESTERS + [nil])}
  validates :graduation_year, numericality: {greater_than: 2010, less_than: 2050, allow_nil: true, only_integer: true}
  validates :graduation_fiscal_year, numericality: {greater_than: 2010, less_than: 2050, allow_nil: true, only_integer: true}
  
  validates :gpa, numericality: {greater_than_or_equal_to: 0.0, less_than_or_equal_to: 4.0, allow_nil: true}
  validates :efficacy_score, numericality: {greater_than_or_equal_to: 0.0, less_than_or_equal_to: 1.0, allow_nil: true}
  
  before_create :generate_key
  after_create :generate_career_steps
  after_create :select_all_opportunity_types
  after_create :send_profile_mailer
  after_save :attempt_fellow_match, if: :missing_user?
  
  scope :receive_opportunities, -> { where(receive_opportunities: true) }
  
  class << self
    def import contents
      CSV.new(contents, headers: true, skip_lines: /(Anticipated Graduation|STUDENT INFORMATION)/).each do |data|
        cohort = Site.cohort_for data['Braven class']

        if cohort.nil?
          puts "COULD NOT FIND A COHORT MATCH FOR #{data['Braven class'].inspect} '#{data['First Name']} #{data['Last Name']}'"
        end

        attributes = {
          first_name: data['First Name'],
          last_name: data['Last Name'],
          phone: data['Phone'],
          email: data['Email'],
          postal_code: cohort.course.site.location.contact.postal_code,
          graduation_year: data['Ant. Grad Year'],
          graduation_semester: data['Ant. Grad Semester'],
          graduation_fiscal_year: 2000 + data['Grad FY'][2..4].to_i,
          interests_description: ensure_string(data['Post-Graduate Career Interests']),
          major: ensure_string(data['Major']),
          affiliations: ensure_string(data['Org Affiliations']),
          gpa: ensure_float(data['GPA']),
          linkedin_url: data['LinkedIn Profile URL'],
          staff_notes: ensure_string(data['Braven Staff Notes']),
          grade: percent_to_decimal(data['Grade']),
          attendance: percent_to_decimal(data['Attendance']),
          nps_response: ensure_int(data['NPS Response']),
          feedback: ensure_string(data['LC feedback']),
          endorsement: strength_for(data['LC Endorsement']),
          professionalism: readiness_for(data['LC professionalism rating']),
          teamwork: readiness_for(data['LC teamwork rating'])
        }

        next unless Course::VALID_SEMESTERS.include?(attributes[:graduation_semester])
        
        cohort.fellows.create_or_update(attributes)
      end
    end
    
    def strength_for string
      ['Not at all Strongly', 'Somewhat Strongly', 'Strongly', 'Very Strongly', 'Extremely Strongly'].index(string)
    end
    
    def readiness_for string
      ['Not at all Ready', 'Slightly Ready', 'Moderately Ready', 'Mostly Ready', 'Completely Ready'].index(string)
    end
    
    def percent_to_decimal string
      (string || '0').gsub(/[^0-9]+/,'').to_f / 100
    end
    
    def ensure_string string
      (string || '').strip
    end
    
    def ensure_int string
      (string || 0).to_i
    end
    
    def ensure_float string
      (string || 0.0).to_f
    end
  end
  
  def cohort
    cohorts.order('id desc').first
  end
  
  def full_name
    [first_name, last_name].join(' ').strip
  end
  
  def graduation
    [graduation_semester, graduation_year].join(' ').strip
  end
  
  def nearest_distance zip_list
    zip_list.map{|zip| distance_from(zip)}.compact.min
  end
  
  def distance_from postal_code
    return @distance_from[postal_code] if defined?(@distance_from) && @distance_from.has_key?(postal_code)
    return nil unless contact && contact.postal_code
    
    @distance_from ||= {}
    @distance_from[postal_code] = PostalCode.distance(assumed_postal_code, postal_code)
  end
  
  def assumed_postal_code
    contact.postal_code || cohort.course.site.location.contact.postal_code
  end
  
  def default_metro
    return @default_metro if defined?(@default_metro)
    
    postal_code = PostalCode.find_by code: contact.postal_code

    @default_metro = if postal_code.nil?
      nil
    else
      Metro.find_by(code: postal_code.msa_code)
    end
  end
  
  def completed_career_steps
    career_steps.completed.pluck(:position)
  end
  
  def completed_career_steps= positions
    career_steps.update_all(completed: false)
    career_steps.where(position: positions).update_all(completed: true)
  end
  
  def receive_opportunities!
    update receive_opportunities: true
  end
  
  def ignore_opportunities!
    update receive_opportunities: false
  end
  
  def select_all_opportunity_types
    self.opportunity_types << OpportunityType.all if self.opportunity_types.empty?
  end
  
  def portal_page_url page_name
    return nil if portal_course_id.nil?

    page_name = page_name.downcase.gsub(/\s+/, '-')
    "#{canvas_url}/courses/#{portal_course_id}/pages/#{page_name}"
  end
  
  def get_portal_resumes
    return nil if portal_course_id.nil? || portal_user_id.nil? || portal_resume_assignment_id.to_i == 0
    
    url = "#{canvas_url}/api/v1/courses/#{portal_course_id}/assignments/#{portal_resume_assignment_id}/submissions/#{portal_user_id}?access_token=#{Rails.application.secrets.canvas_access_token}"
    
    begin
      response = open_url(url)
      data = JSON.parse(response)
      
      data['attachments'].select{|a| a.has_key?('url')}.each do |resume|
        resumes.attach(io: open(resume['url']), filename: resume['filename'])
      end
    rescue
      nil
    end
  end
  
  def portal_resume_assignment_id
    return attributes['portal_resume_assignment_id'] if attributes['portal_resume_assignment_id']
    
    new_id = if classmate = Fellow.where(portal_course_id: portal_course_id).where.not(portal_resume_assignment_id: nil).first
      classmate.portal_resume_assignment_id
    else
      get_portal_assignment_id('resume', 'hustle to career project')
    end
    
    self.update portal_resume_assignment_id: new_id unless new_id.nil?

    attributes['portal_resume_assignment_id']
  end
  
  def get_portal_assignment_id *assignment_names
    return nil if portal_course_id.nil?
    
    page = 1
    assignment_id = nil
    link = 'rel="next"'
    
    while assignment_id.nil? && link.include?('rel="next"')
      url = "#{canvas_url}/api/v1/courses/#{portal_course_id}/assignments?per_page=25&page=#{page}&access_token=#{Rails.application.secrets.canvas_access_token}"
    
      begin
        response = open(url)
        
        link = response.meta['link']
        data = JSON.parse(response.read)

        assignment_names.each do |assignment_name|
          if assignment = data.detect{|x| x['name'].downcase.include?(assignment_name.downcase)}
            assignment_id = assignment['id']
            break
          end
        end
      rescue
        nil
      end
      
      page += 1
    end
    
    assignment_id || 0
  end
  
  def portal_course_id
    return attributes['portal_course_id'] if attributes['portal_course_id']
    
    new_id = get_portal_course_id
    self.update portal_course_id: new_id unless new_id.nil?

    attributes['portal_course_id']
  end
  
  def portal_user_id
    return attributes['portal_user_id'] if attributes['portal_user_id']
    
    new_id = get_portal_user_id
    self.update portal_user_id: new_id unless new_id.nil?

    attributes['portal_user_id']
  end
  
  def get_portal_course_id
    default = nil
    
    begin
      return default unless contact && contact.email
      portal_data['course_ids'].max || default
    rescue
      default
    end
  end
  
  def get_portal_user_id
    default = nil
    
    begin
      return default unless contact && contact.email
      portal_data['user_id'] || default
    rescue
      default
    end
  end
  
  private
  
  def open_url url
    open(url).read
  end
  
  def canvas_url
    url = Rails.application.secrets.canvas_use_ssl ? 'https://' : 'http://'
    url += Rails.application.secrets.canvas_server
    
    unless Rails.application.secrets.canvas_port.blank?
      url += ":#{Rails.application.secrets.canvas_port}"
    end
    
    url
  end
  
  def portal_data
    return @portal_data if defined?(@portal_data)
    
    default = {}
    
    begin
      return default unless contact && contact.email
      
      response = open_url("#{canvas_url}/bz/courses_for_email?email=#{contact.email}")
      @portal_data = JSON.parse(response)
    rescue
      default
    end
  end
  
  def generate_key
    return unless key.nil?
    unique_count = self.class.where(first_name: first_name, last_name: last_name, graduation_year: graduation_year).count
    
    hash = Digest::MD5.hexdigest([first_name, last_name, graduation_year, unique_count].join('-'))[0,4]
    self.key = [first_name[0].upcase, last_name[0].upcase, ((graduation_year || 0) % 100), hash].join('').upcase
  end
  
  def generate_career_steps
    return unless career_steps.empty?

    YAML.load(File.read("#{Rails.root}/config/career_steps.yml")).each_with_index do |step, position|
      career_steps.create position: position, name: step['name'], description: step['description']
    end
  end
  
  def missing_user?
    user_id.nil?
  end
  
  def attempt_fellow_match
    return if contact.nil?
    FellowUserMatcher.match(contact.email)
  end
  
  def access_token
    return @access_token if defined?(@access_token)
    @access_token = AccessToken.for(self)
  end
  
  def send_profile_mailer
    FellowMailer.with(access_token: access_token).profile.deliver_later
  end
end
