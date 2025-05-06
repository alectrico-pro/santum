module Graph
  class Param
    attr_accessor :messaging_product
    attr_accessor :wa_id
    attr_accessor :contacts
    attr_accessor :messages

    def initialize(messaging_product='', wa_id='', contacts=[], messages=[])
      @messaging_product = messaging_product
      @metadata          = wa_id
      @contacts          = contacts
      @messages          = messages
    end

    def save!
    end

    def to_json(*a)
      data = {
               'messaging_product' => @messaging_product,
               'wa_id'             => @wa_id,
               'contacts'          => @contacts,
               'messages'          => @messages }

      { 'json_create'              => self.class.name,
         'data'                    => data.to_json}
    end

    def self.json_create(o)

      attrs = JSON.parse(o['data'], :quirks_mode => true)

      contacts = attrs['contacts']
      contacts_list = []
      if contacts&.any?
        contacts.each do |contact_data|
          contact_json = {'data' => contact_data.to_json}
          contact = ::Graph::Contact.json_create(contact_json)
          contacts_list << contact
        end
      end

      messages = attrs['messages']
      messages_list = []
      if messages&.any?
        messages.each do |message_data|
          message_json = {'data' => message_data.to_json}
          message = ::Graph::Message.json_create(message_json)
          messages_list << message
        end
      end

      ::Graph::Param.new(
                         attrs['messaging_product'],
                         attrs['wa_id'],
                         contacts_list,
                         messages_list )

    end

    def put
      " (params (wa_id #{@wa_id}))"
    end

  end
end
