param publicIpResourceId string


// Output the IP address using an ARM function
output ipAddress string = reference(publicIpResourceId, '2024-01-01', 'full').properties.ipAddress
