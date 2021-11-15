module UserHelper
  def link_to_user(user_id)
    if (user = User.find_by(id: user_id))
      link_to user.kerberos_id, edit_admin_user_path(user.id)
    else
      "ID #{user_id} is not an active user."
    end
  end
end
