package kerosene.v05.application.service.validation.ip_handler.contracts;

import jakarta.servlet.http.HttpServletRequest;

public interface IP {

    String getIP(HttpServletRequest request);
    String getDeviceHash(HttpServletRequest request);



}
