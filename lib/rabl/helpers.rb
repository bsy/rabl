module Rabl
  module Helpers
    # Returns true if item is a ORM record; false otherwise
    # is_record?(@user) => true
    # is_record?([]) => false
    def is_record?(obj)
      obj && data_object(obj).respond_to?(:valid?)
    end

    # Returns a hash based representation of any data object given ejs template block
    # object_to_hash(@user) { attribute :full_name } => { ... }
    # object_to_hash(@user, :source => "...") { attribute :full_name } => { ... }
    def object_to_hash(object, options={}, &block)
      return object unless is_record?(object) || object.respond_to?(:each)
      engine_options = { :format => "hash", :root => options[:root] }
      Rabl::Engine.new(options[:source], engine_options).render(@_scope, :object => object, &block)
    end

    # resolve_condition(:if => true) => true
    # resolve_condition(:if => lambda { |m| false }) => false
    # resolve_condition(:unless => lambda { |m| true }) => true
    def resolve_condition(options)
      return true if options[:if].nil? && options[:unless].nil?
      result = options[:if] == true || (options[:if].respond_to?(:call) && options[:if].call(@_object)) if options.has_key?(:if)
      result = options[:unless] == false || (options[:unless].respond_to?(:call) && !options[:unless].call(@_object)) if options.has_key?(:unless)
      result
    end

    # Returns source for a given relative file
    # fetch_source("show") => "...contents..."
    def fetch_source(file)
      root_path = Rails.root if defined?(Rails)
      root_path = Padrino.root if defined?(Padrino)
      view_path = @_options[:view_path] || File.join(root_path, "app/views/")
      file_path = Dir[File.join(view_path, file + "*.rabl")].first
      File.read(file_path) if file_path
    end

    # data_object(data) => <AR Object>
    # data_object(@user => :person) => @user
    # data_object(:user => :person) => @_object.send(:user)
    def data_object(data)
      data = (data.is_a?(Hash) && data.keys.one?) ? data.keys.first : data
      data.is_a?(Symbol) && @_object ? @_object.send(data) : data
    end

    # data_name(data) => "user"
    # data_name(@user => :person) => :person
    # data_name(@users) => :user
    # data_name([@user]) => "user"
    # data_name([]) => "array"
    def data_name(data)
      return data.values.first if data.is_a?(Hash) # @user => :user
      data = @_object.send(data) if data.is_a?(Symbol) # :address
      if data.respond_to?(:first) && data.first.respond_to?(:valid?)
        data_name(data.first).pluralize
      else # actual data object
        data.class.respond_to?(:model_name) ? data.class.model_name.element : data.class.to_s.downcase
      end
    end
  end
end