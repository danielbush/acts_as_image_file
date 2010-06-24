$MYDBG=false
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
    Tag.delete_all
    TaggedImage.delete_all

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

  test "storing image" do
    i = Image.new
    i.store(test_image1)
    nm = File.join(i.db.root,'originals',File.basename(test_image1))
    assert File.exists?(nm)
    assert_equal File.basename(test_image1),i.name
  end

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
  end

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


  test "we can specify the name field in the database" do
    i = ImageFile.new
    i.image_name = 'foo.jpg'
    i.save!
    assert_equal '/tmp/acts_as_image_file_tests/r2',i.db.root
    p i.url
  end

  # - image_db should be required as version 0.2
  # - add to ImageDB ?
  #   - publish ImageDB gem to github
  # - add git submodule of imagedb to acts as image file?
  # 
  # Test...
  # - we can alter the image name field in the database
  # - storing a real image
  # - retrieving a sized image (autogeneration)
  # - url and path of image are as expected
  # - callbacks work
  #   - see "changing name of an image"
  #     - do this with a real image with sized copies
  #   - have we decided not to bother with destroy?
  #   - any other callbacks to put in?
  # - ar.file_exists? - tests for original's existence
  # - any other methods for analysing, taking stock of image db
  #   vs the AR db?
  #   - originals in ImageDB that are unassigned
  #     - file modify times
  #   - images in AR that don't have an original
  #   

end
