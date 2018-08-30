require 'rails_helper'

# This spec was generated by rspec-rails when you ran the scaffold generator.
# It demonstrates how one might use RSpec to specify the controller code that
# was generated by Rails when you ran the scaffold generator.
#
# It assumes that the implementation code is generated by the rails scaffold
# generator.  If you are using any extension libraries to generate different
# controller code, this generated spec may or may not pass.
#
# It only uses APIs available in rails and/or rspec-rails.  There are a number
# of tools you can use to make these specs even more expressive, but we're
# sticking to rails and rspec-rails APIs to keep things simple and stable.
#
# Compared to earlier versions of this generator, there is very limited use of
# stubs and message expectations in this spec.  Stubs are only used when there
# is no simpler way to get a handle on the object needed for the example.
# Message expectations are only used when there is no simpler way to specify
# that an instance is receiving a specific message.
#
# Also compared to earlier versions of this generator, there are no longer any
# expectations of assigns and templates rendered. These features have been
# removed from Rails core in Rails 5, but can be added back in via the
# `rails-controller-testing` gem.

RSpec.describe Admin::OpportunitiesController, type: :controller do
  render_views
  
  let(:user) { create :admin_user }
  
  # This should return the minimal set of attributes required to create a valid
  # Opportunity. As you add validations to Opportunity, be sure to
  # adjust the attributes here as well.
  let(:employer) { create :employer }
  let(:opportunity_type) { create :opportunity_type }
  let(:region) { create :region }
  
  let(:industry) { create :industry }
  let(:interest) { create :interest }
  let(:saved_employer) { create :employer }
  let(:contact)  { create :contact}
  let(:location) { create :location, contact: contact, locateable: saved_employer }

  let(:valid_attributes) { attributes_for :opportunity, employer_id: employer.id, inbound: true, recurring: true, opportunity_type_id: opportunity_type.id, region_id: region.id, locations_attributes: {"0" => {locateable_type: 'Employer', locateable_id: employer.id, contact_attributes: {postal_code: '12345'}}} }
  let(:invalid_attributes) { { name: ''} }
  
  # This should return the minimal set of values that should be in the session
  # in order to pass any filters (e.g. authentication) defined in
  # OpportunitiesController. Be sure to keep this updated too.
  let(:valid_session) { {} }

  before do
    sign_in user

    allow(Employer).to receive(:find).with(employer.id.to_s).and_return(employer)
    allow_any_instance_of(Opportunity).to receive(:employer).and_return(employer)
  end

  describe 'when signed-in user is not admin' do
    let(:user) { create :fellow_user }

    it "redirects GET #index to home" do
      get :index, params: {}, session: valid_session
      expect(response).to redirect_to(root_path)
    end
    
    it "redirects GET #show to home" do
      get :show, params: {id: '1001'}, session: valid_session
      expect(response).to redirect_to(root_path)
    end

    it "redirects GET #new to home" do
      get :new, params: {employer_id: '1001'}, session: valid_session
      expect(response).to redirect_to(root_path)
    end
    
    it "redirects GET #edit to home" do
      get :edit, params: {id: '1001'}, session: valid_session
      expect(response).to redirect_to(root_path)
    end
    
    it "redirects POST #create to home" do
      post :create, params: {employer_id: '1001', opportunity: valid_attributes}, session: valid_session
      expect(response).to redirect_to(root_path)
    end
    
    it "redirects PUT #update to home" do
      put :update, params: {id: '1001', opportunity: valid_attributes}, session: valid_session
      expect(response).to redirect_to(root_path)
    end
    
    it "redirects DELETE #destroy to home" do
      delete :destroy, params: {id: '1001'}, session: valid_session
      expect(response).to redirect_to(root_path)
    end
  end

  describe "GET #index" do
    it "returns a success response" do
      opportunity = create :opportunity
      get :index, params: {}, session: valid_session
      expect(response).to be_successful
    end
  end
  
  describe 'POST #export' do
    it "returns a success response" do
      post :export, params: {format: 'csv'}, session: valid_session
      expect(response).to be_successful
    end
  end

  describe "GET #show" do
    it "returns a success response" do
      opportunity = create :opportunity
      get :show, params: {id: opportunity.to_param}, session: valid_session
      expect(response).to be_successful
    end
  end

  describe "GET #edit" do
    it "returns a success response" do
      opportunity = create :opportunity
      get :edit, params: {id: opportunity.to_param}, session: valid_session
      expect(response).to be_successful
    end
  end

  describe "PUT #update" do
    context "with valid params" do
      let(:new_name) { valid_attributes[:name] + ' 2' }
      let(:new_attributes) { {name: new_name} }

      it "updates the requested opportunity" do
        opportunity = create :opportunity
        put :update, params: {id: opportunity.to_param, opportunity: new_attributes}, session: valid_session
        opportunity.reload
      
        expect(opportunity.name).to eq(new_name)
      end

      it "redirects to the opportunities path" do
        opportunity = Opportunity.create! valid_attributes
        put :update, params: {id: opportunity.to_param, opportunity: valid_attributes}, session: valid_session
        expect(response).to redirect_to(admin_employer_opportunities_path(opportunity.employer))
      end

      it "associates specified industries with the opportunity" do
        opportunity = create :opportunity
        put :update, params: {id: opportunity.to_param, opportunity: new_attributes.merge(industry_ids: [industry.id.to_s])}, session: valid_session
        opportunity.reload
      
        expect(opportunity.industries).to include(industry)
      end

      it "associates specified interests with the opportunity" do
        opportunity = create :opportunity
        put :update, params: {id: opportunity.to_param, opportunity: new_attributes.merge(interest_ids: [interest.id.to_s])}, session: valid_session
        opportunity.reload
      
        expect(opportunity.interests).to include(interest)
      end

      it "associates specified locations with the opportunity" do
        opportunity = create :opportunity
        put :update, params: {id: opportunity.to_param, opportunity: new_attributes.merge(location_ids: [location.id.to_s])}, session: valid_session
        opportunity.reload
      
        expect(opportunity.locations).to include(location)
      end
    end

    context "with invalid params" do
      it "returns a success response (i.e. to display the 'edit' template)" do
        opportunity = create :opportunity
        put :update, params: {id: opportunity.to_param, opportunity: invalid_attributes}, session: valid_session
        expect(response).to be_successful
      end
    end
  end

  describe "DELETE #destroy" do
    it "destroys the requested opportunity" do
      opportunity = create :opportunity
      expect {
        delete :destroy, params: {id: opportunity.to_param}, session: valid_session
      }.to change(Opportunity, :count).by(-1)
    end

    it "redirects to the opportunities list" do
      opportunity = create :opportunity
      delete :destroy, params: {id: opportunity.to_param}, session: valid_session
      expect(response).to redirect_to(admin_employer_opportunities_url(employer))
    end
  end

  describe "with employer nesting" do    
    describe "GET #index" do
      it "returns a success response" do
        opportunity = create :opportunity
        get :index, params: {employer_id: employer.id}, session: valid_session
        expect(response).to be_successful
      end
    end

    describe "GET #new" do
      it "returns a success response" do
        get :new, params: {employer_id: employer.id}, session: valid_session
        expect(response).to be_successful
      end
    end

    describe "POST #create" do
      context "with valid params" do
        it "creates a new Opportunity" do
          expect {
            post :create, params: {employer_id: employer.id, opportunity: valid_attributes}, session: valid_session
          }.to change(Opportunity, :count).by(1)
        end

        it "redirects to the opportunities path" do
          post :create, params: {employer_id: employer.id, opportunity: valid_attributes}, session: valid_session
          expect(response).to redirect_to(admin_employer_opportunities_path(Opportunity.last.employer))
        end

        it "associates specified industries with the opportunity" do
          post :create, params: {employer_id: employer.id, opportunity: valid_attributes.merge(industry_ids: [industry.id.to_s])}, session: valid_session
          expect(Opportunity.last.industries).to include(industry)
        end

        it "associates specified interests with the opportunity" do
          post :create, params: {employer_id: employer.id, opportunity: valid_attributes.merge(interest_ids: [interest.id.to_s])}, session: valid_session
          expect(Opportunity.last.interests).to include(interest)
        end
        
        it "sets the inbound/recurring booleans" do
          post :create, params: {employer_id: employer.id, opportunity: valid_attributes}, session: valid_session
          opportunity = Opportunity.last
          
          expect(opportunity.inbound).to eq(true)
          expect(opportunity.recurring).to eq(true)
        end
      end

      context "with invalid params" do
        it "returns a success response (i.e. to display the 'new' template)" do
          post :create, params: {employer_id: employer.id, opportunity: invalid_attributes}, session: valid_session
          expect(response).to be_successful
        end
      end
    end
  end
end
