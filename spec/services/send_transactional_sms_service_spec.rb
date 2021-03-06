# frozen_string_literal: true

describe SendTransactionalSmsService, type: :service do
  let(:sms_configuration) { { api_key: "mykey" } }
  let(:rdv) { create(:rdv, organisation: create(:organisation, territory: create(:territory, sms_configuration: sms_configuration))) }
  let(:transactional_sms) do
    instance_double(
      TransactionalSms::RdvCreated,
      phone_number_formatted: "+33606060606",
      content: "Bonjour c'est rdv-sol",
      tags: ["RDV-Sol test", 10, "rdv_created"],
      rdv: OpenStruct.new(rdv.payload)
    )
  end

  describe "#perform" do
    context "production with SIB forced" do
      before do
        allow(ENV).to receive(:[]).with("HOST").and_return("example.com")
        allow(Rails.env).to receive(:production?).and_return(true)
        allow(ENV).to receive(:[]).with("SENDINBLUE_SMS_API_KEY").and_return("send_in_blue")
        allow(ENV).to receive(:[]).with("FORCE_SMS_PROVIDER").and_return("send_in_blue")
      end

      it "calls SIB API" do
        sib_api_mock = instance_double(SibApiV3Sdk::TransactionalSMSApi)
        allow(SibApiV3Sdk::TransactionalSMSApi).to receive(:new).and_return(sib_api_mock)
        expect(sib_api_mock).to receive(:send_transac_sms)
        described_class.new(transactional_sms).perform
      end
    end

    context "debug" do
      before { allow(Rails.env).to receive(:production?).and_return(false) }

      it "does not call netsize nor SIB" do
        expect(SibApiV3Sdk::TransactionalSMSApi).not_to receive(:new)
        described_class.new(transactional_sms).perform
      end
    end
  end
end
