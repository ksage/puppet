require 'puppet/ssl/base'

# Manage certificates themselves.  This class has no
# 'generate' method because the CA is responsible
# for turning CSRs into certificates; we can only
# retrieve them from the CA (or not, as is often
# the case).
class Puppet::SSL::Certificate < Puppet::SSL::Base
  # This is defined from the base class
  wraps OpenSSL::X509::Certificate

  extend Puppet::Indirector
  indirects :certificate, :terminus_class => :file, :doc => <<DOC
    This indirection wraps an `OpenSSL::X509::Certificate` object, representing a certificate (signed public key).
    The indirection key is the certificate CN (generally a hostname).
DOC

  # Because of how the format handler class is included, this
  # can't be in the base class.
  def self.supported_formats
    [:s]
  end

  def subject_alt_names
    alts = content.extensions.find{|ext| ext.oid == "subjectAltName"}
    return [] unless alts
    alts.value.split(/\s*,\s*/)
  end

  def expiration
    return nil unless content
    content.not_after
  end

  def near_expiration?(interval = nil)
    return false unless expiration
    interval ||= Puppet[:certificate_expire_warning]
    # Certificate expiration timestamps are always in UTC
    expiration < Time.now.utc + interval
  end

  # This name is what gets extracted from the subject before being passed
  # to the constructor, so it's not downcased
  def unmunged_name
    self.class.name_from_subject(content.subject)
  end
end
