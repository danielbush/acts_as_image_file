
module ActsAsImageFile

  def self.included base
    base.send :extend , ClassMethods
  end

  module ClassMethods

    # Notes:
    # 
    # * ClassMethods is used to 'extend' our AR class (Image etc...).
    # * so @db and @aaif are "class instance variables"; they are instance
    #   variables of the object that is the AR class (not of instances
    #   of the AR class).
    # * Using class variables (@@var) in ClassMethods does not
    #   work.  We have to use "class instance variables" instead when
    #   storing parameters passed to def acts_as_image_file below.
    #   
    # This approach may be wrong or naive.
    #
    # -- DB, Wed Jun 23 10:20:19 EST 2010


    # Access the image db.

    def db
      @db
    end

    # Access the parameters given at class creation time.

    def aaif
      @aaif
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

      @aaif = params.nil? ? {:name_field => :name} : params
      @db = ImageDb::DB.new(root,@aaif[:rel_root])
      @db.hooks = @aaif[:hooks]

      # Name field should be unique and not null...

      send :validates_uniqueness_of , @aaif[:name_field]
      send :validates_presence_of , @aaif[:name_field]

      # Create some instance methods for this AR class:

      self.module_eval do

        # Convenience method to access image db from an instance.

        def db
          self.class.db
        end

        # Convenience method to access the parameters
        # passed to the invocation of acts_as_image_file.

        def aaif
          self.class.aaif
        end

        # Store an original image...

        def store filepath,params=nil
          db.store filepath,params
        end

        # Retrieve url for original image (resolve to rel_root)...

        def url params=nil
          db.fetch self.send(aaif[:name_field]) , params
        end

        # Retrieve image path...

        def path params=nil
          db.fetch(self.send(aaif[:name_field]) ,
                   params.merge(:absolute => true))
        end

        # Rename images if name is changed.
        # 
        # If image is new or name not set then don't do anything.

        def after_save
          STDERR.puts 'after_destroy'
          return true unless db
          r = self.changes[aaif[:name_field]]
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
          r = db.fetch(self.send(aaif[:name_field]) , params)
          r.nil? ? false : true
        end

      end # module_eval

    end # acts_as_image_file

  end

end

ActiveRecord::Base.send :include , ActsAsImageFile
