package kerosene.v05.contracts;

import jakarta.servlet.http.HttpServletRequest;

public interface IP {

    String getIP(HttpServletRequest request);
    String getDeviceHash(HttpServletRequest request);



}
