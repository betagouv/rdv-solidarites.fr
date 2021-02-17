class Api::V1::UsersController < Api::V1::BaseController
  PERMITTED_PARAMS = [
    :first_name, :birth_name, :last_name, :email, :address, :phone_number,
    :birth_date, :responsible_id, :caisse_affiliation, :affiliation_number,
    :family_situation, :number_of_children, :notify_by_sms, :notify_by_email
  ].freeze

  def show
    user = User.find(params[:id])
    authorize(user)
    render json: UserBlueprint.render(user, root: :user, agent_context: pundit_user)
  end

  def create
    if user_params[:organisation_ids].blank?
      return render(
        status: :unprocessable_entity,
        json: { success: false, errors: ["organisation_ids doit être rempli"] }
      )
    end

    user = User.new(**user_params, skip_duplicate_warnings: true)
    authorize(user)
    user.skip_confirmation_notification!
    if user.save
      render json: UserBlueprint.render(user, root: :user)
    else
      render_invalid_resource(user)
    end
  end

  private

  def user_params
    params.permit(*PERMITTED_PARAMS, organisation_ids: [])
  end
end