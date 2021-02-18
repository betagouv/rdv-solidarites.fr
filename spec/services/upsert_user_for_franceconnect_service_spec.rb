describe UpsertUserForFranceconnectService, type: :service do
  let(:omniauth_info) do
    double( # should be instance_double of OmniAuth::AuthHash::InfoHash
      email: "jeanne@longo.fr",
      given_name: "jeanne",
      family_name: "longo",
      preferred_username: "DUPONT",
      birthdate: Date.parse("1971-06-20"),
      sub: "hvdiuds4357"
    )
  end

  context "no pre-existing user" do
    it "should create a user" do
      service = UpsertUserForFranceconnectService.new(omniauth_info)
      expect { service.perform }.to change { User.count }.by(1)
      expect(service.new_user?).to eq(true)
      user = service.user.reload
      expect(user.email).to eq("jeanne@longo.fr")
      expect(user.first_name).to eq("Jeanne")
      expect(user.birth_name).to eq("LONGO")
      expect(user.last_name).to eq("DUPONT")
      expect(user.birth_date).to eq(Date.parse("1971-06-20"))
      expect(user.franceconnect_openid_sub).to eq("hvdiuds4357")
    end
  end

  context "pre-existing user with same franceconnect sub but different infos" do
    before do
      create(
        :user,
        email: "jeanne@longo.fr",
        franceconnect_openid_sub: "hvdiuds4357",
        logged_once_with_franceconnect: true,
        first_name: "Jeannine",
        birth_name: "LONGINO",
        birth_date: Date.parse("1970-02-15")
      )
    end

    it "should find and return the user without updating its info" do
      service = UpsertUserForFranceconnectService.new(omniauth_info)
      expect { service.perform }.not_to change(User, :count)
      expect(service.new_user?).to eq(false)
      user = service.user.reload
      expect(user.email).to eq("jeanne@longo.fr")
      expect(user.first_name).to eq("Jeannine")
      expect(user.birth_name).to eq("LONGINO")
      expect(user.birth_date).to eq(Date.parse("1970-02-15"))
      expect(user.franceconnect_openid_sub).to eq("hvdiuds4357")
    end
  end

  context "pre-existing user with same email but different infos" do
    before do
      create(
        :user,
        email: "jeanne@longo.fr",
        first_name: "Jeannine",
        last_name: "LONGINO",
        birth_name: nil,
        birth_date: Date.parse("1970-02-15")
      )
    end

    it "should update the existing identity fields" do
      service = UpsertUserForFranceconnectService.new(omniauth_info)
      expect { service.perform }.not_to change(User, :count)
      expect(service.new_user?).to eq(false)
      user = service.user.reload
      expect(user.email).to eq("jeanne@longo.fr")
      expect(user.first_name).to eq("Jeanne")
      expect(user.last_name).to eq("DUPONT")
      expect(user.birth_name).to eq("LONGO")
      expect(user.birth_date).to eq(Date.parse("1971-06-20"))
      expect(user.franceconnect_openid_sub).to eq("hvdiuds4357")
    end
  end

  context "pre-existing user with same email but missing infos" do
    before do
      create(
        :user,
        email: "jeanne@longo.fr",
        birth_date: nil
      )
    end

    it "should fill the missing fields" do
      service = UpsertUserForFranceconnectService.new(omniauth_info)
      expect { service.perform }.not_to change(User, :count)
      expect(service.new_user?).to eq(false)
      user = service.user.reload
      expect(user.birth_date).to eq(Date.parse("1971-06-20"))
      expect(user.franceconnect_openid_sub).to eq("hvdiuds4357")
    end
  end
end
