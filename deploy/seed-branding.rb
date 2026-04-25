# =============================================================================
# Tari Community Discourse — branding seeder
# =============================================================================
# Run via: bundle exec rails runner /shared/tari-seed/seed-branding.rb
#
# Uploads logo/icon assets from the tari-seed directory and configures
# the Tari color scheme and font overrides. IDEMPOTENT — safe to re-run.
#
# Assets must be staged to /shared/tari-seed/assets/ before running.
# Falls back to downloading from GitHub if local files are missing.
# See branding/STYLE_GUIDE.md for full details.
# =============================================================================

require 'open-uri'
require 'tempfile'

SYSTEM_USER = Discourse.system_user

GITHUB_RAW_BASE = 'https://raw.githubusercontent.com/tari-project/community-discourse/main/branding/assets'

# -----------------------------------------------------------------------------
# Helper: upload a file as a site setting image
# -----------------------------------------------------------------------------
def upload_site_image(setting_name, file_path, filename)
  file_to_upload = nil

  if File.exist?(file_path)
    file_to_upload = File.open(file_path)
    puts "[tari-brand] Using local file: #{file_path}"
  else
    # Fallback: download from GitHub raw
    github_url = "#{GITHUB_RAW_BASE}/#{File.basename(file_path)}"
    puts "[tari-brand] Local file #{file_path} not found — downloading from #{github_url}"
    begin
      tmp = Tempfile.new([File.basename(file_path, '.*'), File.extname(file_path)])
      tmp.binmode
      URI.open(github_url) { |remote| tmp.write(remote.read) }
      tmp.rewind
      file_to_upload = tmp
    rescue => e
      puts "[tari-brand] !! Failed to download #{github_url}: #{e.class} #{e.message}"
      return
    end
  end

  begin
    upload = UploadCreator.new(
      file_to_upload,
      filename,
      type: "site_setting"
    ).create_for(SYSTEM_USER.id)

    if upload.persisted?
      SiteSetting.public_send("#{setting_name}=", upload)
      puts "[tari-brand] #{setting_name} = #{upload.url}"
    else
      puts "[tari-brand] !! upload failed for #{setting_name}: #{upload.errors.full_messages.join(', ')}"
    end
  rescue => e
    puts "[tari-brand] !! exception uploading #{setting_name}: #{e.class} #{e.message}"
  ensure
    file_to_upload.close if file_to_upload
  end
end

# -----------------------------------------------------------------------------
# 1. Color scheme
# -----------------------------------------------------------------------------
puts '[tari-brand] Configuring Tari color scheme...'

TARI_COLORS = {
  'primary'           => 'ECEEFF',  # Cloud — text (light on dark bg)
  'secondary'         => '040723',  # Ink — page background (dark)
  'tertiary'          => '813BF5',  # Purple — links (good contrast on dark)
  'quaternary'        => 'C9EB00',  # Green — navigation accent
  'header_background' => '040723',  # Ink — dark header
  'header_primary'    => 'ECEEFF',  # Cloud — header text
  'highlight'         => 'EBC216',  # Yellow — highlights
  'danger'            => 'FE2C3F',  # Red — danger/alerts
  'success'           => 'C9EB00',  # Green — success (bright, visible on dark)
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
  puts "[tari-brand] !! No default theme found — set the color scheme manually in admin."
end

# Disable automatic dark/light switching — dark is the default for everyone.
# Users can still choose a light scheme in their preferences.
SiteSetting.default_dark_mode_color_scheme_id = -1
puts '[tari-brand] Disabled auto dark-mode switching (dark is default)'

# -----------------------------------------------------------------------------
# 2. Upload logo and icon assets
# -----------------------------------------------------------------------------
puts '[tari-brand] Uploading brand assets...'

ASSET_DIR = '/shared/tari-seed/assets'

# Diagnostic: list what's actually in the asset directory
if Dir.exist?(ASSET_DIR)
  files = Dir.entries(ASSET_DIR).reject { |f| f.start_with?('.') }
  puts "[tari-brand] Assets found in #{ASSET_DIR}: #{files.join(', ')}"
else
  puts "[tari-brand] !! Asset directory #{ASSET_DIR} does not exist!"
end

{
  'logo'             => ['logo-dark.png',        'tari-logo.png'],         # White wordmark (dark bg default)
  'logo_small'       => ['logo-small.png',       'tari-logo-small.png'],   # White mark only (dark bg)
  'favicon'          => ['favicon.png',          'tari-favicon.png'],
  'apple_touch_icon' => ['apple-touch-icon.png', 'tari-apple-touch-icon.png'],
  'large_icon'       => ['large-icon.png',       'tari-large-icon.png'],
  'logo_dark'        => ['logo-dark.png',        'tari-logo-dark.png'],    # Same white wordmark
}.each do |setting, (local_name, upload_name)|
  upload_site_image(setting, File.join(ASSET_DIR, local_name), upload_name)
end

# -----------------------------------------------------------------------------
# 3. Font and typography via theme component
# -----------------------------------------------------------------------------
puts '[tari-brand] Configuring typography...'

# Poppins is not in Discourse's built-in font list, so we load it via
# a theme component that injects Google Fonts and overrides the CSS.
TARI_FONT_CSS = <<~SCSS
  @import url('https://fonts.googleapis.com/css2?family=Poppins:wght@400;500;600;700&display=swap');

  :root {
    --font-family: 'Poppins', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, sans-serif;
    --heading-font-family: 'Poppins', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, sans-serif;
  }

  html {
    font-family: var(--font-family);
  }

  h1, h2, h3, h4, h5, h6,
  .topic-list .topic-list-data a.title,
  .category-name {
    font-family: var(--heading-font-family);
  }
SCSS

default_theme = Theme.find_by(id: SiteSetting.default_theme_id) || Theme.where(default: true).first
if default_theme
  # Find or create Tari branding child theme component
  tari_component = Theme.find_by(name: 'Tari Branding')
  unless tari_component
    tari_component = Theme.create!(
      name: 'Tari Branding',
      user_id: SYSTEM_USER.id,
      component: true
    )
    puts "[tari-brand] Created 'Tari Branding' theme component"
  end

  # Set the CSS
  tari_component.set_field(target: :common, name: :scss, value: TARI_FONT_CSS)
  tari_component.save!
  puts "[tari-brand] Updated Tari Branding SCSS"

  # Attach to default theme if not already
  unless default_theme.child_themes.include?(tari_component)
    default_theme.add_relative_theme!(:child, tari_component)
    puts "[tari-brand] Attached 'Tari Branding' component to '#{default_theme.name}'"
  end
else
  puts "[tari-brand] !! No default theme found — cannot set font override."
end

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
    puts "[tari-brand]   !! failed to set #{k}: #{e.message}"
  end
end

puts '[tari-brand] done.'

# Force theme recompilation to pick up all changes
Theme.expire_site_cache!
puts '[tari-brand] Cleared theme cache.'
