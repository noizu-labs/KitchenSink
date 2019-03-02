defprotocol Noizu.Cms.V2.Proto do
  @fallback_to_any true

  def tags(ref, context)
  def set_version(ref, version, context, options)
  def prepare_version(ref, context, options)
  def expand_version(ref, version, context, options)
  def index_details(ref, context, options)

end # end defprotocol
