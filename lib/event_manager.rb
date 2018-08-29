require "csv"
require 'google/apis/civicinfo_v2'
require "erb"

def get_legislators(zipcode)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'
  begin
    legislators = civic_info.representative_info_by_address(
                              address: zipcode,
                              levels: 'country',
                              roles: ['legislatorUpperBody', 'legislatorLowerBody'])
    legislators = legislators.officials
    #legislator_names = legislators.map(&:name).join(", ")
  rescue
    "You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials" 
  end
end

def clean_zipcode(zipcode)
  zipcode.nil? ? "00000": zipcode.rjust(5,"0")[0...5]
end

def clean_phone_num(phone_num)
  if phone_num.length == 11 && phone_num[0] == "1"
    phone_num[1..-1]
  elsif phone_num.length == 10
  	phone_num
  else
  	"Bad Number"
  end
end

def get_peak_hours(regdate)
	hours = Hash.new(0)
	regdate.each do |date|
		date = DateTime.strptime(date,"%d/%m/%Y %H:%M")
		hours[data.hour.to_s] +=1
	end
	hours = hours.sort_by {|hour,reg| reg}.reverse
end

def get_peak_day(regdate)
	days = {"0":"Sunday", "1":"Monday", "2":"Tuesday",
			"3":"Wednesday", "4":"Thursday", "5":"Friday",
			"6":Saturday}
	days_count = Hash.new(0)
	regdate.each do |date|
		date = DateTime.strptime(date,"%d/%m/%Y %H:%M")
		day = days[date.wday.to_s]
		days_count[day] +=1
	end
	days_count = days_count.sort_by {|day,count| count}.reverse
	days_count[0][0]
end

def display_letter(template_letter,name,legislators)
  personal_letter = template_letter.gsub('FIRST_NAME',name)
  personal_letter.gsub!('LEGISLATORS',legislators)
  puts personal_letter
end

def save_letter(id,form_letter)
  Dir.mkdir("output") unless Dir.exists? "output"

  filename = "output/thanks_#{id}.html"

  File.open(filename,'w') do |file|
    file.puts form_letter
  end
end

puts "EventManager initialized."

contents = CSV.open "event_attendees.csv", headers: true, header_converters: :symbol
template_letter = File.read "form_letter.erb"
template = ERB.new(template_letter)
contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  legislators = get_legislators(zipcode)
  form_letter = template.result(binding)
  save_letter(id,form_letter)
end