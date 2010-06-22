
module ActsAsImageFile

  def self.included base
    base.send :extend , ClassMethods
  end

  module ClassMethods

    # Access the image db.
    # 
    # Example:
    #   ar = AR.new
    #   AR.db.absolute(ar.name,:width => 60)
    #   AR.db.fetch(ar.name,:width => 60)

    def db
      @@db
    end

    # Invoked by the AR class that wants this behaviour.
    #
    # +params+ is a hash
    # :hooks      => hook object which uses ImageDb::DB.hooks
    #                functionality
    # :rel_root   => alternative root such as an http alias
    #                eg '/http/alias'
    #                as used by the ImageDb::DB system.
    # :name_field => :name (default)
    #                Name of the field holding the image name.
    #                eg of image name: 'image-1.jpg'

    def acts_as_image_file root , params=nil

      @@acts_as_image_file = params.nil? ? {:name_field => :name} : params
      @@db = ImageDb::DB.new(root,@@acts_as_image_file[:rel_root])
      @@db.hooks = @@acts_as_image_file[:hooks]

      # Name field should be unique and not null...

      send :validates_uniqueness_of , @@acts_as_image_file[:name_field]
      send :validates_presence_of , @@acts_as_image_file[:name_field]

      # Create some instance methods for this AR class:

      self.module_eval do

        # Convenience method to access image db from an instance.

        def db
          self.class.db
        end

        # Store an original image...

        def store filepath,params=nil
          db.store filepath,params
        end

        # Retrieve url for original image...

        def url params=nil
          db.resolve self.send(@@acts_as_image_file[:name_field]) , params
        end

        # Rename images if name is changed.
        # 
        # If image is new or name not set then don't do anything.

        def after_save
          STDERR.puts 'after_destroy'
          return true unless db
          r = self.changes[@@acts_as_image_file[:name_field]]
          return true unless r
          old,new = r
          unless old.nil?
            db.rename(old,new,:force => true) if db
          end
        end

        # Do nothing.  Up to user if they want to destroy images.

        def after_destroy
          STDERR.puts 'after_destroy'
          #db.delete self.name
        end

        # Check original image file exists.

        def file_exists? params=nil
          r = db.fetch(self.send(@@acts_as_image_file[:name_field]) , params)
          r.nil? ? false : true
        end

      end # module_eval

    end # acts_as_image_file

  end

end

ActiveRecord::Base.send :include , ActsAsImageFile
