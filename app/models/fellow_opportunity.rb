class FellowOpportunity < ApplicationRecord
  acts_as_paranoid
  
  belongs_to :fellow
  belongs_to :opportunity
  belongs_to :opportunity_stage
  
  has_one :access_token, as: :owner
  
  has_many :comments, as: :commentable
  has_many :logs, class_name: 'CandidateLog', foreign_key: :candidate_id
  
  validates :fellow_id, presence: true, uniqueness: {scope: :opportunity_id}
  validates :opportunity_id, presence: true
  validates :opportunity_stage_id, presence: true
  
  scope :active, ->{ where(active: true) }
  scope :inactive, -> { where(active: false) }
  
  def log message
    logs.create status: message
  end
  
  def stage
    opportunity_stage.name
  end
  
  def update_stage stage_name, options={}
    case stage_name
    when 'no change'
      if options[:from]
        self.update opportunity_stage: OpportunityStage.find_by(name: options[:from])
      end
      
      log stage

    when 'next'
      next_stage = next_opportunity_stage(options[:from])

      self.update opportunity_stage: next_stage
      log next_stage.name

    when 'skip'
      next_stage = next_opportunity_stage(options[:from])

      self.update opportunity_stage: next_stage
      log "skipped to: #{next_stage.name}"

    else
      self.update opportunity_stage: OpportunityStage.find_by(name: stage_name)
      log stage_name
    end
    
    # set active flag properly
    if ['fellow accepted', 'fellow declined', 'employer declined'].include?(stage)
      self.archive!
    else
      self.activate!
    end
  end
  
  def activate!
    self.update active: true
  end
  
  def archive!
    self.update active: false
  end
  
  private
  
  def next_opportunity_stage from=nil
    position = if from
      OpportunityStage.find_by(name: from).position
    else
      opportunity_stage.position
    end
    
    OpportunityStage.find_by(position: position + 1)
  end
end
