# This file is part of Acts as image file, a ruby on rails plugin.
# Copyright (C) 2010 Daniel Bush
# This program is distributed under the terms of the MIT License.
# See the MIT LICENSE file for details.

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
      @aaif[:name_field] = :name unless @aaif[:name_field]
      @db = ImageDb::DB.new(root,@aaif[:rel_root])
      @db.hooks = @aaif[:hooks]

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
        #
        # We try to save the image name in the active record
        # first.  If this fails we stop.
        # If it succeeds, we store the image in the image db.
        # It's recommended you apply at least a validates_uniqueness_of
        # in the image name field of the active record.

        def store filepath,params=nil
          return false unless File.exists?(filepath)
          params ||= {}
          #raise "File doesn't exist" unless File.exists?(filepath)
          name = ((params && params[:name]) ?
                  params[:name] : File.basename(filepath))
          old_name = self[aaif[:name_field]]
          self[aaif[:name_field]] = name
          return false unless self.save
          nm = db.store(filepath,params.merge(:force => true,:name => name))
            # This could throw an error and abort the whole
            # operation.
          return true
        rescue
          return false
        end

        def store! filepath,params=nil
          raise "Can't store image" if !store(filepath,params)
        end

        # Retrieve url for original image (resolve to rel_root)...

        def url params=nil
          params ||= {}
          name = self.send(aaif[:name_field])
          db.fetch self.send(aaif[:name_field]) , params
          if params[:not_found]
            db.fetch(name,params)
          else
            db.resolve(name,params)
          end
        end

        # Retrieve image path...

        def path params=nil
          params ||= {}
          params = params.merge(:absolute => true)
          name = self.send(aaif[:name_field])
          if params[:not_found]
            # Fetch uses not_found logic
            db.fetch(name,params)
          else
            db.absolute(name,params)
          end
        end

        # Rename images in image db if name field value (image name)
        # is changed.
        # 
        # If image is new or name not set then don't do anything.

        def after_save
          return true unless db
          r = self.changes[aaif[:name_field].to_s]
          return true unless r
          old,new = r
          unless old.nil?
            db.rename(old,new,:force => true) if db
          end
          return true
        end

        # Do nothing.  Up to user if they want to destroy images.

        def after_destroy
          #db.delete self.name
        end

        # Check original image file exists.

        def file_exists? params=nil
          File.exists?(db.absolute(self.send(aaif[:name_field]),
                                   params))
        end

      end # module_eval

    end # acts_as_image_file

  end

end

ActiveRecord::Base.send :include , ActsAsImageFile
