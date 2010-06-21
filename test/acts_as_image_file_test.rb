require 'test_helper'

class ActsAsImageFileTest < ActiveSupport::TestCase
  load_schema
  class Image < ActiveRecord::Base
    acts_as_image_file
  end
  class Tag < ActiveRecord::Base
  end
  class TaggedImage < ActiveRecord::Base
  end

  test "schema loads correctly" do
    assert_equal [],Image.all
    assert_equal [],Tag.all
    assert_equal [],TaggedImage.all
  end

end
