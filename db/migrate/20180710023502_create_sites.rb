Sequel.migration do
  change do

    create_table :sites do
      primary_key :id
      Text :url
      Text :referrer
      DateTime :created_at
      String :hash
    end

  end
end
