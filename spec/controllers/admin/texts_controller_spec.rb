require 'rails_helper'

describe Admin::TextsController do
  let!(:text) { FactoryBot.create :text }

  before(:each) do
    sign_in(FactoryBot.create(:admin))
  end

  it "index action should render index template" do
    get :index
    expect(response).to render_template(:index)
  end

  it "new action should render new template" do
    get :new
    expect(response).to render_template(:new)
  end

  describe "create" do
    it "create action should render new template when model is invalid" do
      post :create
      expect(response).to render_template(:new)
    end

    it "create action should redirect when model is valid" do
      post :create, params: { text: FactoryBot.attributes_for(:text) }
      expect(response).to redirect_to(admin_texts_path)
    end
  end

  describe "update" do
    before do
      @text = FactoryBot.create :text
    end

    it "update action should render edit template when model is invalid" do
      put :update, params: { id: @text, text: { key: '' } }
      expect(response).to render_template(:edit)
    end

    it "update action should redirect when model is valid" do
      put :update, params: { id: @text, text: { key: 'abc' } }
      expect(response).to redirect_to(admin_texts_path)
    end
  end

  it "edit action should render edit template" do
    get :edit, params: { id: text.id }
    expect(response).to render_template(:edit)
  end

  it "destroy action should destroy model and redirect to index action" do
    text = FactoryBot.create :text

    delete :destroy, params: { id: text.id }

    expect(response).to redirect_to(admin_texts_path)
    expect(Text.exists?(text.id)).to be(false)
  end
end
