require 'test_helper'
require 'fileutils'


class ActsAsImageFileTest < ActiveSupport::TestCase

  load_schema

  class Image < ActiveRecord::Base
    acts_as_image_file '/tmp/acts_as_image_file_tests/r1'
  end

  class ImageFile < ActiveRecord::Base
    acts_as_image_file('/tmp/acts_as_image_file_tests/r1' ,
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

    FileUtils.rm_rf '/tmp/acts_as_image_file_tests'
    FileUtils.mkdir_p '/tmp/acts_as_image_file_tests'
  end

  test "schema loads correctly" do
    assert_equal [],Image.all
    assert_equal [],ImageFile.all
    assert_equal [],Tag.all
    assert_equal [],TaggedImage.all
  end

  test "changing name of an image" do
    i = Image.new
    i.name = 'foo.jpg'
    i.save!
    i.name = 'bar.jpg'
    i.save!
    p i.url
  end

  test "we can access the image db from an instance" do
    i = Image.new
    i.name = 'foo.jpg'
    i.save!
    assert_equal '/tmp/acts_as_image_file_tests/r1',i.db.root
    p i.url
  end

  test "we can specify the name field in the database" do
    i = ImageFile.new
    i.image_name = 'foo.jpg'
    i.save!
    assert_equal '/tmp/acts_as_image_file_tests/r1',i.db.root
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
