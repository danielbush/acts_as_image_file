require 'test_helper'
require 'fileutils'


class ActsAsImageFileTest < ActiveSupport::TestCase
  load_schema

  class Image < ActiveRecord::Base
    acts_as_image_file '/tmp/acts_as_image_file_tests/r1'
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
    assert_equal [],Tag.all
    assert_equal [],TaggedImage.all
  end

  test "changing name" do
    i = Image.new
    i.name = 'foo.jpg'
    i.save!
    i.name = 'bar.jpg'
    i.save!
    p i.url
  end


end
