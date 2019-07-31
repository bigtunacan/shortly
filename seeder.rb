require 'pg'
require 'sequel'

DB = Sequel.connect(ENV['DATABASE_URL'] || 'postgres://localhost/mydb')
def init_db
  DB.create_table :short_keys do
    primary_key :id
    String :short_key, unique: true, null: false
    TrueClass :used, default: false
  end

  DB.create_table :key_length do
    primary_key :id
    Integer :length, null: false
  end

  DB.create_table :gen_time do
    primary_key :id
    Float :time, null: false
  end

  DB.create_table :url_mappings do
    primary_key :id
    Integer :short_keys_id
    String :url, null: false
    Integer :request_count, null: false, default: 0
    String :title, null: true
  end

  key_length_table = DB[:key_length]

  # Get an array of all characters generally considered 'safe' to use in a URI and does not require encoding
  # RFC3986
  safe_chars = [*('a'..'z'), *('A'..'Z'), *('0'..'9'), '$', '-', '_', '+', '!', '*', "'", '(', ')', ',']

  # 1 =>              72
  # 2 =>           5,112
  # 3 =>         357,840
  # 4 =>      24,690,960
  # --------------------
  # Total =>  25,053,984

  short_keys = DB[:short_keys]
   #for i in 1..4 do
  for i in 1..2 do
    start_time = Time.now

    key_length_table.insert(length: i)
    perms = safe_chars.permutation(i).each do |perm|
      short_keys.insert(short_key: perm.join, used: false)
      puts perm.join
    end

    end_time = Time.now
    elapsed_time = end_time - start_time
    DB[:gen_time].insert(id: i, time: elapsed_time)
  end
end
