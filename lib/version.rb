# Version representa la version del bot, esta clase tiene un metodo current que devuelve la version actual del bot
class Version
  MAYOR = 0
  MINOR = 0
  PATCH = 16

  def self.current
    "#{MAYOR}.#{MINOR}.#{PATCH}"
  end
end
