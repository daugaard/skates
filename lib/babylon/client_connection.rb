require 'xmpp4r/jid'
require 'xmpp4r/iq'
require 'sasl'

module Babylon
  class ClientConnection < XmppConnection
    def initialize(*a)
      super
      @state = :wait_for_stream
      @tls = false
      @is_authenticated = false
      @sasl = nil
    end

    class XMPPPreferences < SASL::Preferences
      def initialize(connection)
        @connection = connection
      end
      def realm
        @connection.jid.domain
      end
      def digest_uri
        "xmpp/#{@connection.jid.domain}"
      end
      def username
        @connection.jid.node
      end
      def allow_plaintext?
        @connection.is_tls?
      end
    end
    class PasswordPreferences < XMPPPreferences
      def initialize(password, connection)
        @password = password
        super(connection)
      end
      def has_password?
        true
      end
      def password
        @password
      end
    end
    class AnonymousPreferences < XMPPPreferences
      def want_anonymous?
        true
      end
    end

    def receive_stanza(stanza)
      case @state

      when :wait_for_stream
        if stanza.name == 'stream'
          version = stanza.attributes['version']
          if version == '1.0'
            @state = :wait_for_features
          else
            raise 'Please implement non-SASL authentication or upgrade your server'
          end
        else
          raise
        end

      when :wait_for_features
        if stanza.name == 'features'
          @stream_features = stanza
          check_features
        end
        
      when :wait_for_auth
        msg_name, msg_content = stanza.name, (stanza.text ?
                                              Base64::decode64(stanza.text) :
                                              nil)
        msg_name, msg_content = @sasl.receive(msg_name, msg_content)
        if msg_name
          send_sasl_message(msg_name, msg_content)
        end
        if @sasl.success?
          @sasl = nil # Get GC'ed
          @is_authenticated = true
          restart_stream
          @state = :wait_for_stream
          puts "..."
        elsif @sasl.failure?
          raise 'Authentication failure'
        end

      when :wait_for_bind
        if stanza.name == 'iq' && stanza.attributes['id'] == 'bind'
          if stanza.attributes['type'] == 'result'
            @is_bound = true
            check_features
          else
            raise 'Resource binding error'
          end
        end

      when :wait_for_session
        if stanza.name == 'iq' && stanza.attributes['id'] == 'session'
          if stanza.attributes['type'] == 'result'
            @is_session = true
            check_features
          else
            raise 'Session binding error'
          end
        end

      when :connected
        super

      end
    end

    def check_features
      features = []
      @stream_features.each_element { |e| features << e.name }
      
      # TODO: if not @tls
      if not @is_authenticated
        mechanisms = []
        if (mechanisms_element = @stream_features.elements['mechanisms'])
          mechanisms_element.each_element('mechanism') do |mechanism_element|
            mechanisms << mechanism_element.text
          end
        end
        
        pref = if @config['anonymous']
                 AnonymousPreferences.new(self)
               else
                 PasswordPreferences.new(@config['password'], self)
               end
        @sasl = SASL.new(mechanisms, pref)
        msg_name, msg_content = @sasl.start
        send_sasl_message(msg_name, msg_content, @sasl.mechanism)
        @state = :wait_for_auth
      elsif not @is_bound && features.include?('bind')
        iq = Jabber::Iq.new(:set)
        iq.id = 'bind'
        iq.add(bind = REXML::Element.new('bind'))
        bind.add_namespace 'urn:ietf:params:xml:ns:xmpp-bind'
        if jid.resource
          bind.add(REXML::Element.new('resource')).text = jid.resource
        end
        send_xml iq
        @state = :wait_for_bind
      elsif not @is_session && features.include?('session')
        iq = Jabber::Iq.new(:set)
        iq.id = 'session'
        iq.add(session = REXML::Element.new('session'))
        session.add_namespace 'urn:ietf:params:xml:ns:xmpp-session'
        send_xml iq
        @state = :wait_for_session
      else
        puts "*** CONNECTED ***"
        @state = :connected
      end
    end
    
    def send_sasl_message(name, content=nil, mechanism=nil)
      stanza = REXML::Element.new(name)
      stanza.add_namespace(NS_SASL)
      stanza.attributes['mechanism'] = mechanism
      stanza.text = content ? Base64::encode64(content).gsub(/\s/, '') : nil

      send_xml stanza
    end

    NS_SASL = 'urn:ietf:params:xml:ns:xmpp-sasl'

    def stream_namespace
      'jabber:client'
    end

    def stream_to
      jid.domain
    end

    def jid
      @jid ||= Jabber::JID.new(@config['jid'])
    end
  end
end
