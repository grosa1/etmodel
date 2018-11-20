require 'rails_helper'

describe DescriptionsController do
  let!(:chart)   { FactoryBot.create :output_element_with_description}
  let!(:description)   { chart.description}

  describe "#show" do
    it "should show the description template" do
      get :show, params: { id: description.id }
      expect(response).to be_successful
      expect(response).to render_template(:show)
    end
  end

  describe "#charts" do
    it "should return the chart description" do
      get :charts, params: { id: chart.id }
      expect(response).to be_successful
      expect(response).to render_template(:show)
    end
  end
end
