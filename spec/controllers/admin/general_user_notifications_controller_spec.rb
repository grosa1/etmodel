require 'rails_helper'

describe Admin::GeneralUserNotificationsController do
  render_views
  let!(:general_user_notification) { FactoryBot.create :general_user_notification }

  before do
    sign_in(FactoryBot.create(:admin))
  end

  describe "GET new" do
    let(:response) { get(:new) }

    it { expect(response).to be_successful}
    it { expect(response).to render_template :new}
  end

  describe "GET index" do
    let(:response) { get(:index) }

    it { expect(response).to be_successful }
    it { expect(response).to render_template(:index) }
  end

  describe "GET show" do
    let(:response) do
      get :show, params: { id: general_user_notification.id }
    end

    it { expect(response).to be_successful }
    it { expect(response).to render_template(:show) }
  end

  describe "GET edit" do
    let(:response) do
      get :edit, params: { id: general_user_notification.id }
    end

    it { expect(response).to be_successful }
    it { expect(response).to render_template(:edit) }
  end

  describe "PUT update" do
    before do
      @general_user_notification = FactoryBot.create :general_user_notification

      put :update, params: {
        id: @general_user_notification.id,
        general_user_notification: { notification_en: 'another text' }
      }
    end

    it { is_expected.to redirect_to(admin_general_user_notifications_path) }
  end

  describe "DELETE destroy" do
    before do
      @general_user_notification = FactoryBot.create :general_user_notification
      @general_user_notification_count = GeneralUserNotification.count
      delete :destroy, params: { id: @general_user_notification.id }
    end

    it "should delete the GeneralUserNotification" do
      expect(GeneralUserNotification.count).to eq(@general_user_notification_count - 1)
    end
    it { is_expected.to redirect_to(admin_general_user_notifications_path)}
  end
end
