# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Survey::MultipleChoiceQuestion do
  context 'with :background key and three choices: :consultant, :government, :researcher' do
    let(:question) do
      described_class.new(:background, %w[consultant government researcher])
    end

    it 'coerces "consultant" into a translated value' do
      expect(question.coerce_value('consultant'))
        .to eq(I18n.t('survey.questions.background.choices.consultant', locale: :en))
    end

    it 'coerces "government" into a translated value' do
      expect(question.coerce_value('government'))
        .to eq(I18n.t('survey.questions.background.choices.government', locale: :en))
    end

    it 'coerces "researcher" into a translated value' do
      expect(question.coerce_value('researcher'))
        .to eq(I18n.t('survey.questions.background.choices.researcher', locale: :en))
    end

    it 'keeps "student" as a literal value' do
      expect(question.coerce_value('student')).to eq('student')
    end

    it 'keeps "None of your business" as a literal value' do
      expect(question.coerce_value('None of your business')).to eq('None of your business')
    end

    it 'truncated values longer than 256 characters' do
      expect(question.coerce_value('a' * 300).length).to eq(256)
    end

    it 'coerces "" into ""' do
      expect(question.coerce_value('')).to eq('')
    end

    it 'coerces nil into nil' do
      expect(question.coerce_value(nil)).to be_nil
    end
  end
end
