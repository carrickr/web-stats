Sequel.migration do
  change do
    create_table(:schema_migrations) do
      column :filename, "text", :null=>false
      
      primary_key [:filename]
    end
    
    create_table(:sites) do
      primary_key :id
      column :url, "text"
      column :referrer, "text"
      column :created_at, "timestamp without time zone"
      column :hash, "text"
    end
  end
end
Sequel.migration do
  change do
    self << "SET search_path TO \"$user\", public"
    self << "INSERT INTO \"schema_migrations\" (\"filename\") VALUES ('20180710023502_create_sites.rb')"
  end
end
