# Monkey Patch to solve issue https://github.com/jnunemaker/mongomapper/issues/507
# stolen from: https://github.com/jnunemaker/mongomapper/issues/507
module MongoMapper
  module Plugins
    module Querying
      private
        def save_to_collection(options={})
          @_new = false
          collection.save(to_mongo, :w => options[:safe] ? 1 : 0)
        end
    end
  end
end