# frozen_string_literal: true

class Tokens
  attr_accessor :access, :refresh

  def initialize(db)
    @db = db
  end

  def init
    read
  end

  def update(refresh, access)
    save refresh, access
    read
  end

  private

  def read
    self.access, self.refresh = @db.all_tokens
  end

  def save(refresh, access)
    @db.put_tokens refresh, access
  end
end
