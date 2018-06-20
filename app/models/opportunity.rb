class Opportunity < ApplicationRecord
  belongs_to :employer
  
  has_many :tasks, as: :taskable, dependent: :destroy
  accepts_nested_attributes_for :tasks, reject_if: :all_blank, allow_destroy: true
  
  has_many :fellow_opportunities
  has_many :fellows, through: :fellow_opportunities
  
  has_and_belongs_to_many :industries, dependent: :destroy
  has_and_belongs_to_many :interests, dependent: :destroy
  has_and_belongs_to_many :metros, dependent: :destroy

  has_and_belongs_to_many :locations, dependent: :destroy
  accepts_nested_attributes_for :locations, reject_if: :all_blank, allow_destroy: true
  
  validates :name, presence: true
  validates :job_posting_url, url: {ensure_protocol: true}, allow_blank: true
  
  def candidates search_params=nil
    search_params ||= {}
    return @candidates if defined?(@candidates)
    
    candidate_ids = []
    
    # candidates match on either industry or interest overlap
    candidate_ids += fellow_ids_for_interests(search_params[:interests])
    candidate_ids += fellow_ids_for_industries(search_params[:industries])

    # candidates must match on metro, regardless of industry/interest
    candidate_ids &= fellow_ids_for_metros(search_params[:metros])
    
    candidate_ids.uniq!
    
    # remove already-activated candidates
    candidate_ids -= fellow_opportunities.pluck(:fellow_id)
    
    @candidates = Fellow.where(id: candidate_ids)
  end
  
  def fellow_ids_for_interests names
    selected_ids = if names
      Interest.where(name: names.split(';')).pluck(:id)
    else
      interest_ids
    end
    
    FellowInterest.fellow_ids_for(selected_ids)
  end
  
  def fellow_ids_for_industries names
    selected_ids = if names
      Industry.where(name: names.split(';')).pluck(:id)
    else
      industry_ids
    end
    
    FellowIndustry.fellow_ids_for(selected_ids)
  end
  
  def fellow_ids_for_metros names
    selected_ids = if names
      Metro.where(name: names.split(';')).pluck(:id)
    else
      metro_ids
    end
    
    FellowMetro.fellow_ids_for(selected_ids)
  end
  
  def candidate_ids= candidate_id_list
    initial_stage = OpportunityStage.find_by position: 0
    
    candidate_id_list.each do |candidate_id|
      if archived = archived_fellow_opp(candidate_id)
        archived.restore
      else
        fellow_opportunities.create! fellow_id: candidate_id, opportunity_stage: initial_stage
      end
    end
  end
  
  def industry_tags
    industries.pluck(:name).join(';')
  end
  
  def industry_tags= tag_string
    self.industry_ids = Industry.where(name: tag_string.split(';')).pluck(:id)
  end
  
  def interest_tags
    interests.pluck(:name).join(';')
  end
  
  def interest_tags= tag_string
    self.interest_ids = Interest.where(name: tag_string.split(';')).pluck(:id)
  end
  
  def metro_tags
    metros.pluck(:name).join(';')
  end
  
  def metro_tags= tag_string
    self.metro_ids = Metro.where(name: tag_string.split(';')).pluck(:id)
  end
  
  def postal_codes
    locations.map(&:contact).map(&:postal_code)
  end
  
  private
  
  def archived_fellow_opp candidate_id
    FellowOpportunity.with_deleted.find_by(opportunity_id: self.id, fellow_id: candidate_id)
  end
end
