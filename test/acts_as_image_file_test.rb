$MYDBG=false
#require 'rubygems'
#require 'ruby-debug'
require 'test_helper'
require 'fileutils'
require 'find'


class ActsAsImageFileTest < ActiveSupport::TestCase

  load_schema

  def test_image1
    File.join(File.expand_path(File.dirname(__FILE__)),
              '..','lib','image_db','test','test_data',
              'image-w600-h400-300ppi.jpg')
  end

  class Image < ActiveRecord::Base
    acts_as_image_file('/tmp/acts_as_image_file_tests/r1',
                       :rel_root => '/http/alias' )
  end

  # Like Image but with validations.

  class Image2 < ActiveRecord::Base
    acts_as_image_file('/tmp/acts_as_image_file_tests/r1',
                       :rel_root => '/http/alias' )
    validates_uniqueness_of :name
  end

  class ImageFile < ActiveRecord::Base
    acts_as_image_file('/tmp/acts_as_image_file_tests/r2' ,
                       :name_field => :image_name)
  end

  class Tag < ActiveRecord::Base
  end

  class TaggedImage < ActiveRecord::Base
  end

  def setup
    Image.delete_all
    ImageFile.delete_all
    Image2.delete_all
    Tag.delete_all
    TaggedImage.delete_all

    [Image,ImageFile,Image2].each do |o|
      o.db.use_not_found = false
      o.db.not_found_image = nil
    end

    # Delete all images but preserve image db directory structure.
    # Image db creates directory structure at initialize time only.

    Find.find('/tmp/acts_as_image_file_tests/') do |f|
      File.unlink(f) if File.file?(f)
    end

  end

  test "(000) test images are available" do
    assert File.exists?(test_image1)
  end

  test "(000) schema loads correctly" do
    assert_equal [],Image.all
    assert_equal [],ImageFile.all
    assert_equal [],Tag.all
    assert_equal [],TaggedImage.all
  end

  test "(001) we can access the image db from an instance" do
    assert_equal '/tmp/acts_as_image_file_tests/r1',Image.db.root
    i = Image.new
    assert_equal '/tmp/acts_as_image_file_tests/r1',i.db.root
  end

  #------------------------------------------------------------------
  # store

  test "storing image" do
    i = Image.new
    i.store(test_image1)
    nm = File.join(i.db.root,'originals',File.basename(test_image1))
    assert File.exists?(nm)
    assert_equal File.basename(test_image1),i.name
  end

  test "storing image with different name" do
    i = Image.new
    i.store(test_image1,:name => 'foo.jpg')
    nm = File.join(i.db.root,'originals','foo.jpg')
    assert File.exists?(nm)
    assert_equal 'foo.jpg',i.name
  end

  test "storing image where image name already exists in image db" do
    i = Image.new
    i.store(test_image1,:name => 'foo.jpg')

    # Take same i and store a new image (happens to be
    # same test image, but idea still applies...)

    assert i.store(test_image1,:name => 'foo.jpg')

    # Suppose we have a different image record that
    # tries to use the same image name:

    i2 = Image.new
    assert i2.store(test_image1,:name => 'foo.jpg')

  end

  # Repeat the above but with validations....

  test "storing image where image name already exists (with validations)" do
    i = Image2.new
    i.store(test_image1,:name => 'foo.jpg')
    assert i.store(test_image1,:name => 'foo.jpg')
    i2 = Image2.new
    assert !i2.store(test_image1,:name => 'foo.jpg')
    assert_raise RuntimeError do
      i2.store!(test_image1,:name => 'foo.jpg')
    end

  end

  test "storing an image record which isn't backed by an image" do
    i = Image.new
    i.name = 'foo.jpg'
    i.save! # foo.jpg doesn't exist.
    i.store test_image1
    assert_equal File.basename(test_image1),i.name
    assert File.exists?(i.path)
  end

  #------------------------------------------------------------------
  # url and path

  test "accessing url and path" do
    i = Image.new
    i.store(test_image1)
    assert_equal File.join('/','http','alias','originals',
                           File.basename(test_image1)),i.url
    assert_equal File.join(Image.db.root,'originals',
                           File.basename(test_image1)),i.path
  end

  test "autogeneration of sized images using url and path" do
    i = Image.new
    i.store(test_image1)
    nm = i.url(:width => 60)
    assert_equal File.join('/','http','alias','w','60',
                           File.basename(test_image1)),nm
    assert File.exists?(File.join(i.db.root,'w','60',
                                  File.basename(test_image1)))
  end

  test "getting url or path of non-existent image" do
    i = Image.new
    i.name = 'foo.jpg'
    i.save!
    assert /foo.jpg/===i.url
    assert /foo.jpg/===i.path

    # not_found doesn't exist, return nil:
    assert_nil i.url(:not_found => 'image-2.jpg')
    assert_nil i.path(:not_found => 'image-2.jpg')

    # not_found exists, return not found:
    i.store(test_image1,:name => 'image-2.jpg')
    assert /image-2.jpg/===i.url(:not_found => 'image-2.jpg')
    assert /image-2.jpg/===i.path(:not_found => 'image-2.jpg')
    
    # autogeneration of resized not_found images
    assert /image-2.jpg/===i.url(:not_found => 'image-2.jpg',:width => 67)
    assert File.exists?(File.join(i.db.root,'w','67','image-2.jpg'))
  end

  #------------------------------------------------------------------
  # rename (via name field)

  test "changing name of an image" do
    nm = File.join(Image.db.root,'originals',File.basename(test_image1))
    nm2 = File.join(Image.db.root,'originals','bar.jpg')
    i = Image.new
    i.store test_image1
    assert File.exists?(nm)
    assert !File.exists?(nm2)
    i.name = 'bar.jpg'
    i.save!
    assert !File.exists?(nm)
    assert File.exists?(nm2)
  end

  test "renaming an image record which isn't backed by an image" do
    i = Image.new
    i.name = 'foo.jpg'
    i.save!
    # foo.jpg doesn't exist.
    i.name = 'bar.jpg'
    i.save!
    # There should be no problems.
  end


  #------------------------------------------------------------------
  # name field

  test "we can specify the name field in the database" do
    i = ImageFile.new
    i.image_name = 'foo.jpg'
    i.save!
    assert_equal '/tmp/acts_as_image_file_tests/r2',i.db.root
    assert /foo.jpg/===i.url
  end

  #------------------------------------------------------------------
  # file_exists?

  test "file_exists?" do
    i = Image.new
    i.store test_image1 , :name => 'im1.jpg'
    assert i.file_exists? == true
    assert i.file_exists?(:width => 68) == false
    i.url(:width => 68)
    assert i.file_exists?(:width => 68) == true
  end


end
