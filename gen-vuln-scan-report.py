# Anchore Vulnerablity scan report generate 
# Author Anish Nath
# This program will generate report of the docker images which are successfully analyzed by Anchore System

import requests
import csv
import time

image = input("Get Image Vuln: Format (sha256:445d80972082e2dbcc7a9e38f0e7f098472702bcfd9b50274d4d152cc246cf05)  ") 
auth = input("Input Basic Authorization:  ")


url = 'http://localhost:8228/v1/images/'+image+'/vuln/all?vendor_only=True'

payload  = {}
headers = {
  'Content-Type': 'application/json',
  'Authorization': 'Basic ' + auth
}

response = requests.request("GET", url, headers=headers, data = payload)

#print(response.text.encode('utf8'))

vuln_dict=response.json()

#print(vuln_dict['vulnerabilities'])

fileName = (vuln_dict['imageDigest']) + time.strftime("%Y%m%d-%H%M%S") + '.csv'

data_file = open(fileName, 'w')

csv_writer = csv.writer(data_file) 

csv_writer.writerow([
	"feed",  #0
	"feed_group", #1
	"fix", #2
	'package', #3
	'package_cpe', #4
	'package_cpe23', #5
	'package_name', #6
	'package_path', #7
	'package_type', #8
	'package_version', #9
	'severity', #10
	'url', #11
	'vuln', #12
	'id', #13
	'cvss_v2_base_score', #14
	'cvss_v2_exploitability_score', #15
	'cvss_v2_impact_score', #16
	'cvss_v3_base_score', #17
	'cvss_v3_exploitability_score', #18
	'cvss_v3_impact_score' #19
	]) 


for vuln in vuln_dict['vulnerabilities']:
    #print(type(vuln))
    arr = []
    for key in vuln:
    	if key == 'nvd_data':
    		#print(type(vuln[key]))
    		for key2 in vuln[key]:
    			#print(key2)
    			arr.insert(13,key2['id'])
    			arr.insert(14,key2['cvss_v2']['base_score'])
    			arr.insert(15,key2['cvss_v2']['exploitability_score'])
    			arr.insert(16,key2['cvss_v2']['impact_score'])

    			arr.insert(17,key2['cvss_v3']['base_score'])
    			arr.insert(18,key2['cvss_v3']['exploitability_score'])
    			arr.insert(19,key2['cvss_v3']['impact_score'])

    			

    	elif key == 'feed':
    		#print(vuln[key], key)
    		#print(vuln[key])
    		arr.insert(0,vuln[key])

    	elif key == 'feed_group':
    		arr.insert(1,vuln[key])

    	elif key == 'fix':
    		arr.insert(2,vuln[key])

    	elif key == 'package':
    		arr.insert(3,vuln[key])

    	elif key == 'package_cpe':
    		arr.insert(4,vuln[key])

    	elif key == 'package_cpe23':
    		arr.insert(5,vuln[key])

    	elif key == 'package_name':
    		arr.insert(6,vuln[key])

    	elif key == 'package_path':
    		arr.insert(7,vuln[key])

    	elif key == 'package_type':
    		arr.insert(8,vuln[key])

    	elif key == 'package_version':
    		arr.insert(9,vuln[key])

    	elif key == 'severity':
    		arr.insert(10,vuln[key])

    	elif key == 'url':
    		arr.insert(11,vuln[key])

    	elif key == 'vuln':
    		arr.insert(12,vuln[key])
	

    csv_writer.writerow(arr)	


data_file.close()

print ('Vun Report Generated ' + fileName)