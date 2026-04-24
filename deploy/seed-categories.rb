# =============================================================================
# Tari Community Discourse — category + trust-level seeder
# =============================================================================
# Run via: bundle exec rails runner /shared/tari-seed/seed-categories.rb
#
# This script is IDEMPOTENT. It uses `find_or_create_by!(name:)` for every
# category so re-running never duplicates. Safe to run after upgrades.
#
# Category layout rationale is documented in docs/CATEGORIES.md.
# =============================================================================

ADMIN = User.find_by(admin: true) || Discourse.system_user

def ensure_category(name:, slug:, description:, color: 'FE2C3F', text_color: 'FFFFFF', parent: nil, permissions: nil, position: nil)
  cat = Category.find_or_create_by!(name: name) do |c|
    c.user_id     = ADMIN.id
    c.slug        = slug
    c.description = description
    c.color       = color
    c.text_color  = text_color
    c.parent_category_id = parent&.id
    c.position    = position
  end
  # Always refresh description/permissions on re-run so edits to this file
  # propagate by simply re-running the seeder.
  cat.update!(
    description: description,
    color: color,
    text_color: text_color,
    parent_category_id: parent&.id,
    position: position
  )
  cat.set_permissions(permissions) if permissions
  cat.save!
  puts "[tari-seed] category: #{name} (id=#{cat.id})"
  cat
end

# -----------------------------------------------------------------------------
# Trust-level ACL shortcuts
# -----------------------------------------------------------------------------
# Discourse permission levels: :full (see/reply/create),
# :create_post (see/reply), :readonly (see only).
EVERYONE_READ    = { everyone: :readonly, trust_level_0: :create_post, trust_level_1: :full }
EVERYONE_FULL    = { everyone: :full }
TL1_UP_FULL      = { everyone: :readonly, trust_level_1: :full }
TL2_UP_FULL      = { everyone: :readonly, trust_level_2: :full }
STAFF_ONLY       = { staff: :full }
STAFF_READ_TL3   = { trust_level_3: :readonly, staff: :full }

# -----------------------------------------------------------------------------
# Top-level categories
# -----------------------------------------------------------------------------
announcements = ensure_category(
  name: 'Announcements',
  slug: 'announcements',
  description: 'Official news from the Tari core team. Read-only for everyone; only staff can post here.',
  color: 'FE2C3F',
  permissions: { everyone: :readonly, staff: :full },
  position: 0
)

general = ensure_category(
  name: 'General Discussion',
  slug: 'general',
  description: 'The town square. Chat about Tari, the Ootle, privacy practices, or anything on-topic.',
  color: '808281',
  permissions: EVERYONE_READ,
  position: 1
)

technical = ensure_category(
  name: 'Technical',
  slug: 'technical',
  description: 'Implementation-level discussions: protocol, consensus, cryptography, node operation, mining, wallets, and client/core development.',
  color: '3AB54A',
  permissions: EVERYONE_READ,
  position: 2
)

# Technical sub-categories
ensure_category(
  name: 'Node & Mining',
  slug: 'technical-node-mining',
  description: 'Running base nodes, mining lanes, merge mining with Monero, hashrate troubleshooting.',
  parent: technical,
  permissions: EVERYONE_READ
)
ensure_category(
  name: 'Wallets',
  slug: 'technical-wallets',
  description: 'Console wallet, mobile wallets, FFI, Ledger integration, recovery, seed words.',
  parent: technical,
  permissions: EVERYONE_READ
)
ensure_category(
  name: 'Client Development',
  slug: 'technical-client-dev',
  description: 'Building apps and services on Tari — RPC/gRPC, wallet SDK, Ootle smart contracts, libraries, and integrations.',
  parent: technical,
  permissions: EVERYONE_READ
)
ensure_category(
  name: 'Core Development',
  slug: 'technical-core-dev',
  description: 'Contributing to Tari itself — protocol, consensus, cryptography, contract/templating features, and tari-project repos.',
  parent: technical,
  permissions: EVERYONE_READ
)

governance = ensure_category(
  name: 'Governance & Proposals',
  slug: 'governance',
  description: 'Community proposals, network parameters, upgrade discussions. TL1+ to post.',
  color: 'F7931E',
  permissions: TL1_UP_FULL,
  position: 3
)

support = ensure_category(
  name: 'Support',
  slug: 'support',
  description: 'Stuck? Ask here. Please search before posting, and include logs + versions.',
  color: '12A89D',
  permissions: EVERYONE_FULL,
  position: 4
)

marketplace = ensure_category(
  name: 'Marketplace',
  slug: 'marketplace',
  description: 'Community buy/sell/trade. Coin talk is limited to XTM/TARI/wXTM — other tokens, wrappers, and yield products are off-topic. TL2+ to post.',
  color: '652D90',
  permissions: TL2_UP_FULL,
  position: 5
)

ensure_category(
  name: 'Staff',
  slug: 'staff',
  description: 'Private category for moderators and admins.',
  color: '231F20',
  permissions: STAFF_ONLY,
  position: 99
)

ensure_category(
  name: 'Lounge',
  slug: 'lounge',
  description: 'Reserved for TL3 (Regular) members and staff. Earned by participation.',
  color: 'A5CF47',
  permissions: STAFF_READ_TL3,
  position: 98
)

# -----------------------------------------------------------------------------
# Site settings — moderation + trust level tuning
# -----------------------------------------------------------------------------
puts '[tari-seed] applying site settings...'

settings = {
  # Security / abuse
  'min_post_length'                 => 20,
  'min_first_post_length'           => 20,
  'body_min_entropy'                => 7,
  'title_min_entropy'               => 6,
  'num_flags_to_close_topic'        => 5,
  'num_users_to_silence_new_user'   => 3,
  'cooldown_minutes_after_hiding_posts' => 10,
  'max_mentions_per_post'           => 10,
  'newuser_max_links'               => 2,
  'newuser_max_mentions_per_post'   => 2,
  'newuser_max_images'              => 1,

  # Trust level auto-promote thresholds (see docs/TRUST_LEVELS.md)
  'tl1_requires_topics_entered'     => 5,
  'tl1_requires_read_posts'         => 30,
  'tl1_requires_time_spent_mins'    => 10,

  'tl2_requires_topics_entered'     => 20,
  'tl2_requires_read_posts'         => 100,
  'tl2_requires_time_spent_mins'    => 60,
  'tl2_requires_days_visited'       => 15,
  'tl2_requires_likes_received'     => 1,
  'tl2_requires_likes_given'        => 1,
  'tl2_requires_topic_reply_count'  => 3,

  'tl3_time_period'                 => 100,
  'tl3_requires_days_visited'       => 50,
  'tl3_requires_topics_replied_to'  => 10,
  'tl3_requires_topics_viewed'      => 25,
  'tl3_requires_posts_read'         => 500,
  'tl3_requires_likes_given'        => 30,
  'tl3_requires_likes_received'     => 20,

  # Backups
  'backup_frequency'                => 1,
  'maximum_backups'                 => (ENV['BACKUP_RETENTION_DAYS'] || '14').to_i,

  # Login / signup
  'enable_local_logins'             => true,
  'allow_new_registrations'         => true,
  'must_approve_users'              => false,
  'login_required'                  => false,

  # Branding
  'title'                           => 'Tari Community',
  'site_description'                => 'Official forum for the Tari community — privacy, mining, wallets, governance.',
}

settings.each do |k, v|
  begin
    SiteSetting.public_send("#{k}=", v)
    puts "[tari-seed]   #{k} = #{v}"
  rescue => e
    warn "[tari-seed]   !! failed to set #{k}: #{e.message}"
  end
end

puts '[tari-seed] done.'
