# =============================================================================
# Tari Community Discourse — branding seeder
# =============================================================================
# Run via: bundle exec rails runner /shared/tari-seed/seed-branding.rb
#
# Uploads logo/icon assets from the tari-seed directory and configures
# the Tari color scheme and font overrides. IDEMPOTENT — safe to re-run.
#
# Assets must be staged to /shared/tari-seed/assets/ before running.
# See branding/STYLE_GUIDE.md for full details.
# =============================================================================

SYSTEM_USER = Discourse.system_user

# -----------------------------------------------------------------------------
# Helper: upload a file as a site setting image
# -----------------------------------------------------------------------------
def upload_site_image(setting_name, file_path, filename)
  unless File.exist?(file_path)
    warn "[tari-brand] !! #{file_path} not found — skipping #{setting_name}"
    return
  end

  upload = UploadCreator.new(
    File.open(file_path),
    filename,
    type: "site_setting"
  ).create_for(SYSTEM_USER.id)

  if upload.persisted?
    SiteSetting.public_send("#{setting_name}=", upload)
    puts "[tari-brand] #{setting_name} = #{upload.url}"
  else
    warn "[tari-brand] !! upload failed for #{setting_name}: #{upload.errors.full_messages.join(', ')}"
  end
end

# -----------------------------------------------------------------------------
# 1. Color scheme
# -----------------------------------------------------------------------------
puts '[tari-brand] Configuring Tari color scheme...'

TARI_COLORS = {
  'primary'           => '040723',  # Ink — main text
  'secondary'         => 'FBF1E9',  # Off White — page background
  'tertiary'          => '0939CF',  # Azure — links (better contrast than Purple)
  'quaternary'        => '813BF5',  # Purple — navigation accent
  'header_background' => '040723',  # Ink — dark header
  'header_primary'    => 'ECEEFF',  # Cloud — header text
  'highlight'         => 'EBC216',  # Yellow — highlights
  'danger'            => 'FE2C3F',  # Red — danger/alerts
  'success'           => '3AB54A',  # Muted green (C9EB00 is too bright on white)
  'love'              => '813BF5',  # Purple — like button
}

scheme = ColorScheme.find_by(name: 'Tari Brand')
if scheme
  puts '[tari-brand] Updating existing "Tari Brand" color scheme...'
  TARI_COLORS.each do |name, hex|
    color = scheme.colors.find_by(name: name)
    if color
      color.update!(hex: hex)
    else
      scheme.colors.create!(name: name, hex: hex)
    end
  end
else
  puts '[tari-brand] Creating "Tari Brand" color scheme...'
  scheme = ColorScheme.create!(
    name: 'Tari Brand',
    colors: TARI_COLORS.map { |name, hex| { name: name, hex: hex } }
  )
end

# Set as the default color scheme for the default theme
default_theme = Theme.find_by(id: SiteSetting.default_theme_id) || Theme.where(default: true).first
if default_theme
  default_theme.update!(color_scheme_id: scheme.id)
  puts "[tari-brand] Applied 'Tari Brand' scheme to theme '#{default_theme.name}'"
else
  warn "[tari-brand] !! No default theme found — set the color scheme manually in admin."
end

# -----------------------------------------------------------------------------
# 2. Upload logo and icon assets
# -----------------------------------------------------------------------------
puts '[tari-brand] Uploading brand assets...'

ASSET_DIR = '/shared/tari-seed/assets'

{
  'logo'             => ['logo.png',             'tari-logo.png'],
  'logo_small'       => ['logo-small.png',       'tari-logo-small.png'],
  'favicon'          => ['favicon.png',          'tari-favicon.png'],
  'apple_touch_icon' => ['apple-touch-icon.png', 'tari-apple-touch-icon.png'],
  'large_icon'       => ['large-icon.png',       'tari-large-icon.png'],
  'logo_dark'        => ['logo-dark.png',        'tari-logo-dark.png'],
}.each do |setting, (local_name, upload_name)|
  upload_site_image(setting, File.join(ASSET_DIR, local_name), upload_name)
end

# -----------------------------------------------------------------------------
# 3. Font and typography via theme CSS
# -----------------------------------------------------------------------------
puts '[tari-brand] Configuring typography...'

# Base font — Poppins via Google Fonts
SiteSetting.base_font = 'poppins'
puts "[tari-brand] base_font = poppins"

# Heading font — also Poppins (Druk requires self-hosting, start with Poppins)
SiteSetting.heading_font = 'poppins'
puts "[tari-brand] heading_font = poppins"

# -----------------------------------------------------------------------------
# 4. Additional branding settings
# -----------------------------------------------------------------------------
puts '[tari-brand] Setting additional brand properties...'

{
  'title'                     => 'Tari Community',
  'site_description'          => 'Official forum for the Tari community — privacy, mining, wallets, governance.',
  'short_site_description'    => 'Tari Community Forum',
  'company_name'              => 'Tari Labs',
}.each do |k, v|
  begin
    SiteSetting.public_send("#{k}=", v)
    puts "[tari-brand]   #{k} = #{v}"
  rescue => e
    warn "[tari-brand]   !! failed to set #{k}: #{e.message}"
  end
end

puts '[tari-brand] done.'
