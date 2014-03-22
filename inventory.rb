require 'redis'
$r = Redis.new
Camping.goes :Inventory
module Inventory::Controllers
 class Index < R '/'
  def get
   render :index
  end
 end
 class Search < R '/search'
  def get
   render :search
  end
 end
 class Set < R '/set'
  def get
   $r.sadd('items', @input.name)
   $r.hset(@input.name, @input.field, @input.value)
   render :index
  end
 end
 class Get < R '/get'
  def get
   render :get
  end
 end
 class Delete < R '/del'
  def get
   $r.srem('items', @input.name)
   $r.del(@input.name)
   render :index
  end
 end
end
module Inventory::Views
 def index
  html do
   head do
    title "Inventory"
   end
   body do
    form :action => "search" do
     select :name => "field" do
      option :value => 'any' do
       text "Any"
      end
      option :value => 'name' do
       text "Name"
      end
      option :value => 'cost' do
       text "Cost"
      end
      option :value => 'title' do
       text "Title"
      end
      option :value => 'location' do
       text "Location"
      end
      option :value => 'owner' do
       text "Owner"
      end
     end
     text " "
     select :name => "kind" do
      option :value => 'match' do
       text "Matches"
      end
      option :value => 'contains' do
       text "Contains"
      end
     end
     text " "
     input :type => :text, :name => "string"
     text " "
     input :type => :submit, :value => "Submit"
    end
    br
    br
    table :border => "1" do
      tr do
       th "Quantity"
       th "Name"
       th "Title"
       th "Cost"
       th "Location"
       th "Owner"
      end
      items = $r.smembers('items')
      items.each do |item|
        quantity = $r.hget(item, 'quantity') || "1"
        title = $r.hget(item, 'title') || item
        cost = $r.hget(item, 'cost') || "none"
        location = $r.hget(item, 'location') || "none"
        owner = $r.hget(item, 'owner') || "none"
        tr do
         td quantity
         td item
         td title
         td cost
         td location
         td owner
        end
       end
    end
    br
    br
    form :action => "set" do
     input :type => :text, :name => "name"
     text " "
     select :name => "field" do
      option :value => 'title' do
       text "Title"
      end
      option :value => 'cost' do
       text "Cost"
      end
      option :value => 'location' do
       text "Location"
      end
      option :value => 'owner' do
       text "Owner"
      end
      option :value => 'quantity' do
       text "Quantity"
      end
     end
     text " "
     input :type => :text, :name => "value"
     text " "
     input :type => :submit, :value => "Set"
    end
    br
    form :action => "get" do
     input :type => :text, :name => "name"
     text " "
     input :type => :submit, :value => "Get"
    end
    br
    form :action => "del" do
     input :type => :text, :name => "name"
     text " "
     input :type => :submit, :value => "Delete"
    end
   end
  end
 end
 def search
  foundItems = []
  items = $r.smembers('items')
  if @input.field == "any"
   items.each do |item|
    if @input.kind == "match"
     if $r.hvals(item).include?(@input.string)
      foundItems.push item
     end
    elsif @input.kind == "contains"
     catch :found do
      $r.hvals(item).each do |value|
       if value.include?(@input.string)
        foundItems.push item
        throw :found
       end
      end
     end
    end
   end
  elsif @input.field == "name"
   items.each do |item|
    if @input.kind == "match" and item == @input.string
     foundItems.push item
    elsif @input.kind == "contains" and item.include?(@input.string)
     foundItems.push item
    end
   end
  elsif @input.field == "cost"
   items.each do |item|
    if @input.kind == "match" and $r.hget(item, 'cost') == @input.string
     foundItems.push item
    elsif @input.kind == "contains" and $r.hget(item, 'cost') and $r.hget(item, 'cost').include?(@input.string)
     foundItems.push item
    end
   end
  elsif @input.field == "title"
   items.each do |item|
    if @input.kind == "match" and $r.hget(item, 'title') == @input.string
     foundItems.push item
    elsif @input.kind == "contains" and $r.hget(item, 'title') and $r.hget(item, 'title').include?(@input.string)
     foundItems.push item
    end
   end
  elsif @input.field == "location"
   items.each do |item|
    if @input.kind == "match" and $r.hget(item, 'location') == @input.string
     foundItems.push item
    elsif @input.kind == "contains" and $r.hget(item, 'location') and $r.hget(item, 'location').include?(@input.string)
     foundItems.push item
    end
   end
  elsif @input.field == "owner"
   items.each do |item|
    if @input.kind == "match" and $r.hget(item, 'owner') == @input.string
     foundItems.push item
    elsif @input.kind == "contains" and $r.hget(item, 'owner') and $r.hget(item, 'owner').include?(@input.string)
     foundItems.push item
    end
   end
  end
  if foundItems.empty?
   text "Nothing found."
  else
   table :border => "1" do
    tr do
     th "Quantity"
     th "Name"
     th "Title"
     th "Cost"
     th "Location"
     th "Owner"
    end
    foundItems.each do |item|
     quantity = $r.hget(item, 'quantity') || "1"
     title = $r.hget(item, 'title') || item
     cost = $r.hget(item, 'cost') || "none"
     location = $r.hget(item, 'location') || "none"
     owner = $r.hget(item, 'owner') || "none"
     tr do
      td quantity
      td item
      td title
      td cost
      td location
      td owner
     end
    end
   end
  end
 end
 def get
  if $r.hvals(@input.name).empty?
   text "#{@input.name} not found."
  else
   quantity = $r.hget(@input.name, 'quantity') || "1"
   title = $r.hget(@input.name, 'title') || @input.name
   cost = $r.hget(@input.name, 'cost') || "none"
   location = $r.hget(@input.name, 'location') || "none"
   owner = $r.hget(@input.name, 'owner') || "none"
   table :border => '1' do
    tr do
     th "Quantity"
     th "Name"
     th "Title"
     th "Cost"
     th "Location"
     th "Owner"
    end
    tr do
     td quantity
     td @input.name
     td title
     td cost
     td location
     td owner
    end
   end
  end
 end
end
