require 'test_helper'

class ActsAsImageFileTest < ActiveSupport::TestCase
  load_schema
  class Image < ActiveRecord::Base
  end
  class Tag < ActiveRecord::Base
  end
  class TaggedImage < ActiveRecord::Base
  end

  # Replace this with your real tests.
  test "schema loads correctly" do
    assert_equal [],Image.all
    assert_equal [],Tag.all
    assert_equal [],TaggedImage.all
  end

end
