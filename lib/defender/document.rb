module Defender
  ##
  # A document contains data to be analyzed by Defensio, or that has been
  # analyzed.
  class Document
    ##
    # Whether the document should be published on your Web site or not.
    #
    # For example, spam and malicious content are not allowed.
    #
    # @return [Boolean]
    attr_accessor :allow
    alias_method :allow?, :allow

    ##
    # The information about the document. This hash accepts so many parameters
    # I won't list them here. Go look at the [Defensio API docs]
    # (http://defensio.com/api) instead.
    #
    # Defender will replace all underscores in keys with dashes, so you can use
    # `:author_email` instead of `'author-email'`.
    #
    # @return [Hash{#to_s => #to_s}]
    attr_accessor :data

    ##
    # A unique identifier for the document.
    #
    # This is needed to retrieve the status back from Defensio and to submit
    # false negatives/positives to Defensio. Signatures should be kept private
    # and never shared with your users.
    #
    # @return [String]
    attr_reader :signature

    ##
    # Retrieves the status of a document back from Defensio.
    #
    # Please note that this only retrieves the status of the document (like
    # it's spaminess, whether it should be allowed or not, etc.) and not the
    # content of the request (all of the data in the {#data} hash).
    #
    # @param [String] signature The signature of the document to retrieve
    # @return [Document,nil] The document to retrieve, or nil
    def self.find(signature)
      document = new
      ret = Defender.call(:get_document, signature)
      if ret
        document.instance_variable_set(:@saved, true)
        document.instance_variable_set(:@allow, ret.last['allow'])
        document.instance_variable_set(:@signature, signature)

        document
      else
        nil
      end
    end

    ##
    # Initializes a new document
    def initialize
      @data = {}
      @saved = false
    end

    ##
    # @return [Boolean] Has the document been submitted to Defensio?
    def saved?
      @saved
    end

    ##
    # Submit the document to Defensio.
    #
    # This will send all of the {#data} if the document hasn't been saved
    # before. If it has been saved, it will submit whether the document was a
    # false positive/negative (set the {#allow} param before saving to do
    # this).
    #
    # @see #saved?
    # @return [Boolean] Whether the save succeded or not.
    def save
      if saved?
        ret = Defender.call(:put_document, @signature, {:allow => @allow})
        return false if ret == false
      else
        ret = Defender.call(:post_document, normalized_data)
        return false if ret == false
        data = ret.last
        @allow = data['allow']
        @signature = data['signature']
      end

      @saved = true # This will also return true, since nothing failed as we got here
    end

    private

    ##
    # Normalizes a data hash to submit to defensio.
    #
    # @param [Hash] hsh The hash to be normalized
    # @return [Hash{String => String}] The normalized hash
    def normalized_data
      normalized = {}
      @data.each { |key, value|
        normalized[key.to_s.gsub('_','-')] = value.to_s
      }
      
      normalized
    end
  end
end
