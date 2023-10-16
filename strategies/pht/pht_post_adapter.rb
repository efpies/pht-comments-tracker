# frozen_string_literal: true

module PhtPostAdapter
  def multi_table?
    raise 'Not implemented'
  end

  def header?(_row)
    raise 'Not implemented'
  end

  def post?(_row)
    raise 'Not implemented'
  end

  def to_table_post_entry(_row)
    raise 'Not implemented'
  end

  def get_time_table(_row)
    raise 'Not implemented'
  end

  def get_post_id(_post)
    raise 'Not implemented'
  end

end
