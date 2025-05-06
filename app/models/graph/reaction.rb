module Graph
  class Reaction
    attr_accessor :message_id
    attr_accessor :emoji

    def initialize(message_id='', emoji='')
      @message_id  = message_id
      @emoji       = emoji
    end

    def save!
    end

    def to_json(*a)
      data = { 'message_id'  => @message_id,
               'emoji'       => @emoji }
      { 'json_class' => self.class.name,
        'data' => data.to_json(*a) }
    end
    
    def self.json_create(o)
      attrs = JSON.parse(o['data'], :quirks_mode => true )
      message_id  = attrs['message_id']
      emoji = attrs['emoji']
      n = ::Graph::Reaction.new(message_id, emoji)
    end

    def put(msg_id=nil)
      fact_format = " (reaction "

      unless msg_id.nil?
        fact_format += "(msg_id #{msg_id}) "
      end

      unless @message_id.blank?
        fact_format += " (message_id #{@message_id})"
      end

      unless @emoji.blank?
        fact_format += " (emoji #{@emoji})"
      end
      fact_format += ' )'
    end

  end
end
