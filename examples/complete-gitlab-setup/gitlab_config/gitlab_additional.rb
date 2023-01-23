gitlab_rails['omniauth_providers'] = [
  {
    name: "google_oauth2",
    app_id: "google_oauth_app_id",
    app_secret: "google_oauth_app_secret",
    args: { access_type: "offline", approval_prompt: "" }
  }
]
