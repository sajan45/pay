require 'pstore'
require 'open3'

module Pay
  module DB
    @@store = PStore.new("pay.pstore")

    def self.save_object(obj, root_key, key = nil)
      # possible data structure => {users: {u1: {name: 'u1'}}, my_val: ["data"]}
      # root key can only be an Hash or Array
      @@store.transaction do
        root_type = key ? Hash : Array
        @@store[root_key] ||= root_type.new
        if key
          @@store[root_key][key] = obj
        else
          @@store[root_key] << obj
        end
      end
    end

    def self.get_object(root_key, key = nil)
      # read-only mode, no write access allowed
      @@store.transaction(true) do
        if key
          @@store[root_key] && @@store[root_key][key]
        else
          @@store[root_key]
        end
      end
    end

    def self.remove_db
      begin
        Open3.capture3("rm #{@@store.path}")
      rescue
        # do nothing
      end
    end
  end
end
