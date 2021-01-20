describe TransactionalSms::Builder, type: :service do
  describe "#with" do
    let(:rdv) { build(:rdv) }
    let(:user) { build(:user) }
    subject { TransactionalSms::Builder.with(rdv, user, event_type) }

    context "rdv_created" do
      let(:event_type) { :rdv_created }
      it { should be_an_instance_of(TransactionalSms::RdvCreated) }
    end

    context "file_attente" do
      let(:event_type) { :file_attente }
      it { should be_an_instance_of(TransactionalSms::FileAttente) }
    end

    context "rdv_cancelled" do
      let(:event_type) { :rdv_cancelled }
      it { should be_an_instance_of(TransactionalSms::RdvCancelled) }
    end

    context "reminder" do
      let(:event_type) { :reminder }
      it { should be_an_instance_of(TransactionalSms::Reminder) }
    end
  end
end
