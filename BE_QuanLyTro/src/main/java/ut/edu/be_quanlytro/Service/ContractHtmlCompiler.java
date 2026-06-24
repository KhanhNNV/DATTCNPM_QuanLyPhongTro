package ut.edu.be_quanlytro.Service;

import org.springframework.stereotype.Component;
import ut.edu.be_quanlytro.Entity.Contract;
import ut.edu.be_quanlytro.Entity.ContractTemplate;
import ut.edu.be_quanlytro.Entity.Room;
import ut.edu.be_quanlytro.Entity.User;

@Component
public class ContractHtmlCompiler {

    public String compileContractTerms(ContractTemplate template, Contract contract, User landlord, User tenant, Room room) {

        // 1. ĐỊNH NGHĨA KHUNG PHÁP LÝ CỨNG (Bất khả xâm phạm)
        String baseHtmlFrame = """
            <div style="font-family: Arial, sans-serif; padding: 20px;">
                <h2 style="text-align: center;">CỘNG HÒA XÃ HỘI CHỦ NGHĨA VIỆT NAM</h2>
                <h3 style="text-align: center;">Độc lập - Tự do - Hạnh phúc</h3>
                <h1 style="text-align: center;">HỢP ĐỒNG THUÊ PHÒNG TRỌ</h1>
                
                <p>Hôm nay, ngày {{START_DATE}}, chúng tôi gồm có:</p>
                
                <h4>BÊN A (BÊN CHO THUÊ):</h4>
                <p>Ông/Bà: <b>{{LANDLORD_NAME}}</b></p>
                <p>Số điện thoại: {{LANDLORD_PHONE}}</p>
                
                <h4>BÊN B (BÊN THUÊ):</h4>
                <p>Ông/Bà: <b>{{TENANT_NAME}}</b></p>
                <p>Số điện thoại: {{TENANT_PHONE}}</p>
                <p>CCCD/CMND: {{TENANT_ID_CARD}}</p>
                
                <hr/>
                
                <h4>ĐIỀU 1: NỘI DUNG THUÊ PHÒNG</h4>
                <div>{{RENTAL_CONTENT}}</div>
                
                <h4>ĐIỀU 2: TRÁCH NHIỆM BÊN A (CHỦ TRỌ)</h4>
                <div>{{LANDLORD_DUTY}}</div>
                
                <h4>ĐIỀU 3: TRÁCH NHIỆM BÊN B (KHÁCH THUÊ)</h4>
                <div>{{TENANT_DUTY}}</div>
                
                <h4>ĐIỀU 4: ĐIỀU KHOẢN THỰC HIỆN CHUNG</h4>
                <div>{{EXECUTION_TERMS}}</div>
                
                <hr/>
                <table style="width: 100%; text-align: center; margin-top: 50px;">
                    <tr>
                        <td><b>ĐẠI DIỆN BÊN A</b><br/>{{LANDLORD_SIGNATURE_PLACEHOLDER}}</td>
                        <td><b>ĐẠI DIỆN BÊN B</b><br/>{{TENANT_SIGNATURE_PLACEHOLDER}}</td>
                    </tr>
                </table>
            </div>
        """;

        // 2. NHỒI DỮ LIỆU TỪ MẪU CỦA CHỦ TRỌ VÀO KHUNG
        String html = baseHtmlFrame
                .replace("{{RENTAL_CONTENT}}", template.getRentalContent() != null ? template.getRentalContent() : "")
                .replace("{{LANDLORD_DUTY}}", template.getLandlordDuty() != null ? template.getLandlordDuty() : "")
                .replace("{{TENANT_DUTY}}", template.getTenantDuty() != null ? template.getTenantDuty() : "")
                .replace("{{EXECUTION_TERMS}}", template.getExecutionTerms() != null ? template.getExecutionTerms() : "");

        // 3. NHỒI THÔNG TIN CÁ NHÂN VÀ PHÒNG
        html = html.replace("{{START_DATE}}", contract.getStartDate() != null ? contract.getStartDate().toString() : "")
                .replace("{{LANDLORD_NAME}}", landlord.getFullName() != null ? landlord.getFullName() : "")
                .replace("{{LANDLORD_PHONE}}", landlord.getPhone() != null ? landlord.getPhone() : "")
                .replace("{{TENANT_NAME}}", tenant.getFullName() != null ? tenant.getFullName() : "")
                .replace("{{TENANT_PHONE}}", tenant.getPhone() != null ? tenant.getPhone() : "")
                .replace("{{TENANT_ID_CARD}}", tenant.getIdCardNumber() != null ? tenant.getIdCardNumber() : "");

        // 4. CHỮ KÝ SỐ
        String landlordSig = landlord.getLandlordSignature();
        if (landlordSig != null && !landlordSig.trim().isEmpty()) {
            html = html.replace("{{LANDLORD_SIGNATURE_PLACEHOLDER}}", String.format("<img src='%s' width='150'/>", landlordSig));
        } else {
            html = html.replace("{{LANDLORD_SIGNATURE_PLACEHOLDER}}", "[Chưa có chữ ký]");
        }

        html = html.replace("{{TENANT_SIGNATURE_PLACEHOLDER}}", "<span style='color:red; font-weight:bold;'>[Chờ khách thuê ký điện tử]</span>");

        return html;
    }
}