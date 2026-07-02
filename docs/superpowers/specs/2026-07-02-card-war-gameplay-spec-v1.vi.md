# SIÊU Ý TƯỞNG — GAME THẺ BÀI CHIẾN THUẬT THỜI VŨ KHÍ LẠNH  
## Gameplay Design Specification — Bản tổng hợp ý tưởng đã thống nhất

**Trạng thái:** Bản thiết kế gameplay nền tảng  
**Mục tiêu:** Mô tả đầy đủ ý tưởng, vòng chơi, hệ thống chiến tranh, thẻ bài, tướng, hậu cần, sĩ khí, thông tin và định hướng PvE/PvP.  
**Lưu ý:** Tài liệu này chỉ nói về **ý tưởng và gameplay**, không đề cập công nghệ, kiến trúc phần mềm hay cách lập trình.

---

# 1. Tầm nhìn trò chơi

Đây là một game thẻ bài chiến thuật theo lượt, mô phỏng chiến tranh thời vũ khí lạnh.

Người chơi không đóng vai một chiến binh trực tiếp trên chiến trường. Người chơi là **Đại tướng quan / Tổng chỉ huy**, có trách nhiệm:

- lựa chọn tướng;
- phân công nhiệm vụ;
- điều quân;
- bảo vệ hậu cần;
- tổ chức trinh sát;
- ra lệnh phục kích;
- công hoặc vây thành;
- duy trì sĩ khí;
- quyết định thời điểm tiến, giữ hoặc rút.

Thẻ bài không đại diện cho phép thuật. Mỗi thẻ là một **mệnh lệnh quân sự**.

Ví dụ:

- hành quân;
- dựng trại;
- vận lương;
- trinh sát;
- phục kích;
- vây thành;
- công thành;
- nghi binh;
- mừng công.

Trọng tâm của game không chỉ là “quân nhiều hơn thì thắng”. Chiến thắng đến từ việc phối hợp đúng:

- quân số;
- lương thảo;
- sĩ khí;
- thời gian;
- địa hình;
- thời tiết;
- tướng;
- thông tin;
- vị trí trên bản đồ.

---

# 2. Bản sắc cốt lõi

## 2.1. Thẻ bài là mệnh lệnh

Người chơi sử dụng thẻ bài để giao mệnh lệnh cho một chủ thể trên bản đồ.

Chủ thể có thể là:

- một tướng;
- một đạo quân;
- một thành;
- một doanh trại;
- một đoàn vận lương;
- một đội trinh sát;
- một khu vực;
- một mệnh lệnh đang thực hiện.

Không phải thẻ nào cũng dùng theo cùng một cách.

Ví dụ:

- Hành quân cần chọn đạo quân, tướng, quân số, điểm xuất phát và điểm đến.
- Thu lương chỉ cần chọn một thành.
- Mừng công cần chọn một đạo quân hoặc thành vừa chiến thắng.
- Nghi binh cần chọn một mệnh lệnh hành quân đang chuẩn bị hoặc đang thực hiện.
- Phục kích cần chọn đạo quân, vị trí bố trí và hướng đặt đội hình.

## 2.2. Chiến tranh là hậu cần

Quân số lớn không chỉ là sức mạnh. Quân số lớn đồng nghĩa với:

- tiêu hao lương nhiều hơn;
- hành quân chậm hơn;
- dễ bị phát hiện hơn;
- cần doanh trại lớn hơn;
- khó đi qua địa hình hẹp;
- dễ rơi vào khủng hoảng nếu bị cắt tiếp tế.

Người chơi có thể thắng mà không cần tiêu diệt toàn bộ quân địch.

Một đạo quân hoặc thành có thể tự sụp đổ vì:

- thiếu lương;
- bị vây quá lâu;
- bị cắt tuyến tiếp tế;
- sĩ khí giảm về 0;
- thất bại liên tiếp;
- không thể rút quân.

## 2.3. Thông tin không bao giờ đầy đủ

Đối phương có thể biết một đạo quân đang xuất phát từ đâu, đang di chuyển bao xa và đã đi được bao nhiêu ô, nhưng không biết chính xác điểm đến.

Trinh sát có giá trị vì nó giúp người chơi:

- phát hiện các hành động bán công khai;
- xác định vệt hành quân;
- nhận ra đoàn vận lương;
- tránh phục kích;
- kiểm chứng nghi binh.

Game không sử dụng xác suất lộ diện phức tạp trong chế độ cơ bản.

Thông tin được quyết định bằng những điều kiện rõ ràng:

- loại hành động;
- vị trí;
- phạm vi quan sát;
- đường đi thực tế;
- có trinh sát hay không.

---

# 3. Vai trò người chơi

Người chơi là Tổng chỉ huy.

Người chơi không trực tiếp xuất hiện như một tướng trên bản đồ. Quyền lực của người chơi nằm ở việc:

- lựa chọn đội hình tướng;
- xây dựng bộ bài;
- phân công đúng người;
- quản lý nhiều mặt trận;
- giữ hậu phương;
- dự đoán kế hoạch của đối thủ;
- chấp nhận hoặc né tránh rủi ro.

Mỗi trận, người chơi chọn **10 tướng**.

Mỗi tướng có:

- một loại tướng;
- tính cách và khí chất;
- nội tại riêng;
- ba lá bài riêng được thêm vào bộ bài của trận.

---

# 4. Ba loại tướng

Hệ thống tướng chỉ chia thành ba loại để dễ tiếp cận nhưng vẫn giữ chiều sâu.

## 4.1. Chiến tướng

Chiến tướng mạnh khi trực tiếp dẫn quân.

Đặc trưng:

- giao chiến;
- giữ thành;
- rút quân;
- duy trì đội hình;
- giảm tổn thất;
- chống tan rã;
- tổ chức các hành động quân sự trực tiếp.

Chiến tướng thường có lá bài liên quan đến:

- tiến quân;
- tử chiến;
- phản công;
- rút lui;
- giữ thành;
- đánh chính diện.

## 4.2. Mưu sĩ

Mưu sĩ mạnh về:

- trinh sát;
- nghi binh;
- điều phối;
- thông tin;
- thay đổi cách thực hiện mệnh lệnh;
- hỗ trợ nhiều nhiệm vụ.

Mưu sĩ không nhất thiết phải trực tiếp dẫn đạo quân đang sử dụng kế sách.

Ví dụ:

- đội hình có một mưu sĩ phù hợp thì cơ chế Nghi binh được mở khóa;
- mưu sĩ có thể lập kế hoạch từ hậu phương;
- một đạo quân do chiến tướng dẫn vẫn có thể được áp dụng kế sách của mưu sĩ.

## 4.3. Nội thần

Nội thần mạnh về:

- lương thảo;
- sản xuất;
- vận lương;
- ổn định dân;
- chiêu binh;
- duy trì hậu phương;
- phục hồi sau chiến thắng;
- tổ chức chiến tranh dài hạn.

Nội thần có thể không mạnh ở tiền tuyến, nhưng thường quyết định liệu chiến dịch có thể tiếp tục hay không.

---

# 5. Tướng mẫu đã hình thành

## 5.1. Thượng tướng Asun

**Loại:** Chiến tướng  
**Khí chất:** Hữu dũng vô mưu, tính tình cứng rắn, quân kỷ thép.

### Nội tại — Quân Kỷ Thép

Khi trực tiếp dẫn quân:

- giảm hao quân khi giao chiến;
- giảm nguy cơ tan rã khi sĩ khí thấp.

### Ba lá bài riêng

#### Ngậm Tăm Tiến Quân

Một biến thể đặc biệt của Hành quân.

- Khi đạo quân dưới một ngưỡng quân số nhất định, hành quân có thể chuyển từ Công khai sang Bán công khai.
- Đổi lại, đạo quân phải trả giá lớn về sĩ khí.
- Thể hiện khả năng giữ kỷ luật và hành quân im lặng.

#### Tử Chiến Hộ Thành

Một mệnh lệnh phòng thủ cực đoan.

- Tăng khả năng giữ thành.
- Ngăn thành đầu hàng trong thời gian hiệu lực.
- Đổi lại, quân phòng thủ phải chịu tổn thất hoặc suy giảm sĩ khí nặng sau đó.

#### Nhổ Trại Rút Quân

Một mệnh lệnh rút khỏi vị trí nguy hiểm.

- Giúp đạo quân thoát khỏi tình thế bị vây hoặc sắp thiếu lương.
- Có thể phải bỏ lại một phần lương, trang bị hoặc vị trí chiến lược.

## 5.2. Tướng Gia Cát

**Loại:** Mưu sĩ  
**Khí chất:** Văn võ song toàn, mưu cầu sách lược.

### Nội tại — Đa Nhiệm Chiến Lược

Có thể đảm nhiệm nhiều loại nhiệm vụ:

- tấn công;
- thủ thành;
- trinh sát;
- hậu phương.

Đổi lại, khi đảm nhiệm một nhiệm vụ không đúng sở trường chính, hiệu quả bị giảm.

Tướng này không vượt trội tuyệt đối ở từng nhiệm vụ, nhưng linh hoạt và có các lá bài mạnh.

### Ba lá bài riêng

#### Dương Đông

Nghi binh cấp cao.

- Tạo sức ép thông tin lớn hơn Nghi binh cơ bản.
- Có thể làm đối phương nhận định sai quy mô hoặc hướng di chuyển.
- Không tạo quân thật và không tăng sức mạnh chiến đấu thật.

#### Hậu Phương Vững Chắc

Biến Dựng trại thành một điểm tựa chiến dịch.

- Sau khi dựng trại, quá trình vận lương có thể bắt đầu nhanh hơn.
- Giúp đạo quân giữ vị trí lâu hơn.
- Nếu điểm tựa bị phá, tổn thất hậu cần có thể lớn.

#### Trinh Sát Thần Tốc

Thay thế hoặc nâng cấp Trinh sát cơ bản.

- Tiếp cận vị trí trinh sát nhanh hơn.
- Có thể mở thông tin sớm hơn.
- Giá trị chính nằm ở thời điểm, không nhất thiết là phạm vi lớn hơn.

## 5.3. Tướng hậu cần Mình A Chấm

**Loại:** Nội thần  
**Khí chất:** Nhạy bén, trung thành; hành quân tới đâu, lương thảo tới trước.

### Nội tại — Vận Lương Thuần Thục

Khi trực tiếp phụ trách đoàn vận lương:

- giảm thiệt hại khi bị tập kích;
- không rơi vào trạng thái hoảng loạn khi bị tập kích;
- khi bị cướp lương, có thể đốt lương để đối phương không thu được chiến lợi phẩm.

Bên mình vẫn mất số lương bị đốt. Nội tại này bảo vệ chiến lược, không tạo thêm tài nguyên.

### Ba lá bài riêng

#### Vận Lương Xuyên Suốt

Biến Vận lương từ kiểu “đến nơi mới nhận toàn bộ” thành kiểu lương được chuyển đến dần theo từng lượt.

Giá trị:

- tiền tuyến nhận được lợi ích sớm;
- chiến dịch ít bị ngắt quãng;
- tuyến lương trở thành mục tiêu cần bảo vệ liên tục.

#### Hướng Về Hậu Phương

Chỉ có thể dùng sau khi Vận Lương Xuyên Suốt đã được kích hoạt.

- Mình A Chấm có thể rời khỏi việc trực tiếp phụ trách tuyến hiện tại.
- Sau đó có thể tham gia tổ chức một tuyến vận lương khác xuất phát từ thành chính.
- Thể hiện khả năng điều phối nhiều tuyến hậu cần.

#### Mở Tiệc Mừng Công

Sau khi chiếm thành:

- phục hồi sĩ khí của đạo quân hoặc thành về mức tối đa;
- mạnh hơn Mừng công cơ bản;
- phải tiêu tốn một lượng lương đáng kể.

---

# 6. Bộ bài và cơ chế rút bài

## 6.1. Mười lá bài trên tay

Người chơi có tối đa **10 lá bài trên tay**.

Mỗi lá bài:

- tiêu tốn năng lượng;
- đại diện cho một mệnh lệnh;
- có điều kiện sử dụng;
- có thời gian thực thi;
- có mức độ lộ diện;
- có yêu cầu về quân số, vị trí hoặc lương thảo.

## 6.2. Mười hai lá bài cơ bản

Mười hai lá bài cơ bản tạo thành nền móng của game:

1. Hành quân  
2. Dựng trại  
3. Rút quân  
4. Thu lương  
5. Vận lương  
6. Mừng công  
7. Trinh sát  
8. Thám báo  
9. Phục kích  
10. Vây thành  
11. Công thành  
12. Nghi binh  

## 6.3. Lá bài riêng của tướng

Mỗi tướng được chọn đưa thêm ba lá bài vào bộ bài của trận.

Nếu chọn 10 tướng, bộ bài có thể được mở rộng thêm tối đa 30 lá bài tướng.

Lá bài tướng thường dựa trên một lá bài cơ bản nhưng:

- đổi tên;
- thêm hiệu ứng;
- thay điều kiện;
- thay mức lộ diện;
- thay phạm vi;
- thay chi phí;
- thay cách tính tổn thất;
- thay thời điểm nhận lợi ích.

Ví dụ:

- Ngậm Tăm Tiến Quân dựa trên Hành quân.
- Vận Lương Xuyên Suốt dựa trên Vận lương.
- Trinh Sát Thần Tốc dựa trên Trinh sát.
- Mở Tiệc Mừng Công dựa trên Mừng công.

Các lá bài tướng không xuất hiện chắc chắn. Chúng có **tỷ lệ rút** trong bộ bài.

Vì vậy, lựa chọn 10 tướng không chỉ tạo ra nội tại, mà còn ảnh hưởng trực tiếp đến:

- card pool;
- nhịp rút bài;
- khả năng tạo combo;
- lối chơi toàn trận.

## 6.4. Năng lượng

Mỗi lá bài tốn năng lượng.

Năng lượng:

- giới hạn số mệnh lệnh trong một lượt;
- tăng dần theo tiến trình trận đấu;
- có mức tối đa;
- buộc người chơi lựa chọn giữa nhiều hành động quan trọng.

Các con số cụ thể chưa khóa.

---

# 7. Thời gian và tiến trình hành động

## 7.1. Một lượt bằng ba ngày

Quy ước hiện tại:

> **1 lượt = 3 ngày trong chiến dịch.**

Đây là thang thời gian cân bằng giữa:

- hành quân;
- trinh sát;
- phục kích;
- tập kích;
- vận lương;
- vây thành;
- công thành.

Người chơi không tự khai báo số lượt.

Mỗi hành động tự tính thời gian dựa trên:

- khoảng cách;
- địa hình;
- thời tiết;
- quân số;
- loại quân;
- tướng;
- thẻ bài;
- trạng thái hiện tại.

## 7.2. Hành động kéo dài nhiều lượt

Một mệnh lệnh có thể không hoàn thành ngay.

Ví dụ:

- Hành quân mất nhiều lượt để đến đích.
- Trinh sát cần thời gian tiếp cận và duy trì.
- Phục kích có thời gian bố trí và thời gian chờ.
- Vây thành duy trì liên tục.
- Công thành có thể kéo dài nhiều lượt.

Một tướng đang thực hiện nhiệm vụ bị khóa cho đến khi nhiệm vụ kết thúc, trừ khi có một lá bài đặc biệt thay đổi quy tắc.

## 7.3. Vị trí tướng là vị trí thật

Tướng không dịch chuyển tức thời.

Nếu Tướng A vừa chiếm Thành Z, hành động tiếp theo của Tướng A phải xuất phát từ Thành Z hoặc vị trí hiện tại của đạo quân do tướng đó chỉ huy.

Điều này tạo ra:

- nhiều mặt trận;
- nhu cầu phân công tướng;
- rủi ro tướng bị mắc kẹt;
- giá trị của việc giữ thành và dựng trại;
- giá trị của tuyến hậu cần.

---

# 8. Bản đồ

## 8.1. Bản đồ tutorial

Bản đồ tutorial sử dụng bàn cờ vuông **16 x 16**.

Bố cục định hướng:

- thành phe mình ở phía dưới;
- thành phe địch ở phía trên;
- hướng tiến công chính từ dưới lên;
- thành bên thứ ba nằm ở giữa hoặc hai bên;
- sông, rừng, đồng bằng và núi tạo ra các đường hành quân khác nhau.

## 8.2. Các loại ô chính

- Đồng bằng.
- Sông hoặc hồ.
- Rừng.
- Rừng rậm.
- Núi hoặc khu vực hiểm trở.
- Thành phe mình.
- Thành địch.
- Thành bên thứ ba.
- Doanh trại.
- Các điểm chiến lược khác được bổ sung sau.

## 8.3. Thành nhiều ô

Thành không chỉ chiếm một ô.

Quy mô thành được thể hiện bằng số ô:

- thành lớn có thể chiếm 3–4 ô;
- thành nhỏ hoặc thành bên thứ ba có thể chiếm 1–3 ô;
- quy mô ảnh hưởng đến:
  - sức chứa;
  - sản lượng;
  - khả năng phòng thủ;
  - số hướng có thể bị vây;
  - phạm vi công thành.

## 8.4. Thành bên thứ ba

Thành bên thứ ba không nhất thiết là kẻ địch.

Người chơi có thể:

- công thành;
- vây thành;
- khuyên hàng;
- đáp ứng một số điều kiện để thành quy phục;
- bỏ qua;
- để thành trở thành vùng đệm.

Sau khi chiếm thành, người chơi phải lựa chọn:

- giữ thành;
- điều quân phòng thủ;
- ổn định dân;
- vận lương;
- hoặc bỏ thành.

Chiếm được thành không đồng nghĩa với giữ được thành.

---

# 9. Footprint — diện tích chiếm ô

Footprint là diện tích thật mà một chủ thể hoặc hành động chiếm trên bản đồ.

Footprint giúp quân số và quy mô trở thành yếu tố trực quan.

## 9.1. Doanh trại

Doanh trại có kích thước dựa trên quân số.

Quy ước ban đầu:

> Khoảng 2.000 quân chiếm một ô doanh trại.

Ví dụ:

- 2.000 quân: 1 ô;
- 4.000 quân: 2 ô;
- 6.000 quân: 3 ô;
- 8.000 quân: 4 ô.

Doanh trại lớn:

- dễ bị phát hiện hơn;
- khó bảo vệ hơn;
- cần nhiều lương hơn;
- có thể kiểm soát nhiều khu vực hơn;
- khó dựng tại địa hình hẹp.

## 9.2. Trinh sát

Trinh sát:

- chiếm 1 ô;
- tạo một vùng quan sát rộng hơn vị trí thật;
- không đại diện cho một đại quân lớn.

## 9.3. Phục kích

Phục kích không chiếm một khối vuông lớn.

Đội hình cơ bản được bố trí thành hai hàng:

```text
A A
. .
A A
```

Hai hàng 1x2 cách nhau một hàng trống.

Ý nghĩa:

- hai cánh phục kích ẩn ở hai phía;
- hàng giữa là hành lang quân địch đi vào;
- quân phục kích có thể bắn cung hoặc lao ra từ các ô xung quanh.

Đội hình có thể xoay theo hướng địa hình hoặc đường hành quân của đối phương.

## 9.4. Vây thành

Vây thành chiếm các ô xung quanh biên thành.

Người chơi không nhất thiết phải bao vây toàn bộ ngay từ đầu.

Mức độ bao vây phụ thuộc:

- quân số;
- địa hình;
- số mặt thành bị khóa;
- đường sông;
- núi;
- đường tiếp tế còn mở.

---

# 10. Influence — phạm vi ảnh hưởng

Phạm vi ảnh hưởng khác với diện tích chiếm ô.

Một chủ thể có thể chỉ chiếm một ô nhưng ảnh hưởng đến nhiều ô xung quanh.

## 10.1. Trinh sát

Trinh sát chiếm 1x1 nhưng có vùng quan sát **5x5**.

Nếu một hành động Bán công khai đi qua vùng 5x5:

- hành động bị phát hiện;
- đối phương thấy như một hành động Công khai;
- vẫn không thấy điểm đến cuối cùng.

## 10.2. Thám báo

Thám báo là trinh sát di động.

Khác Trinh sát:

- không giữ một vùng lâu;
- di chuyển theo tuyến;
- quan sát một vùng nhỏ quanh vị trí hiện tại;
- phù hợp để dò sâu và xác định đường đi.

## 10.3. Phục kích

Phạm vi ảnh hưởng của phục kích là:

- hành lang ở giữa đội hình;
- các ô ngay xung quanh;
- vùng cung tên hoặc vùng lao ra.

Khi quân địch đi vào vùng ảnh hưởng, phục kích được kích hoạt.

## 10.4. Doanh trại

Doanh trại có vùng ảnh hưởng xung quanh để:

- xác định khu vực đóng quân;
- nhận vận lương;
- phát hiện hành động áp sát;
- làm cơ sở cho phòng thủ, tập kích và vây trại sau này.

## 10.5. Vây thành

Phạm vi ảnh hưởng của Vây thành tác động đến:

- sĩ khí thành;
- lương thành;
- khả năng nhận tiếp viện;
- đường rút;
- điều kiện đầu hàng;
- khả năng công thành.

---

# 11. Hệ thống thông tin và mức độ lộ diện

Mỗi hành động có một trong ba mức độ lộ diện.

## 11.1. Công khai

Đối phương luôn biết hành động đang diễn ra.

Đối phương biết:

- điểm xuất phát;
- loại hoạt động tổng quát;
- vị trí hiện tại hoặc tiến trình;
- số ô đã di chuyển;
- tốc độ tương đối;
- có thể biết quy mô ước lượng.

Đối phương không biết:

- điểm đến cuối cùng;
- toàn bộ đường đi tương lai;
- ý định cuối cùng.

Ví dụ:

Một đạo quân đi từ Thành Z đến một điểm cách 15 ô trong 5 lượt.

Mỗi lượt đi khoảng 3 ô.

Đối phương thấy:

- quân xuất phát từ Thành Z;
- hiện đã đi được 3, 6 hoặc 9 ô;
- quân đang hành quân.

Đối phương không thấy:

- quân đang nhắm Thành A, Thành B hay một doanh trại;
- điểm cuối của đường đi.

## 11.2. Bán công khai

Mặc định đối phương không thấy.

Hành động chỉ bị lộ khi:

- đường hành quân;
- footprint;
- hoặc vùng hoạt động

đi qua phạm vi Trinh sát của đối phương.

Sau khi bị phát hiện, hành động được hiển thị tương tự Công khai:

- thấy nguồn;
- thấy tiến trình;
- không thấy đích.

## 11.3. Bí mật

Đối phương không thấy hành động trong chế độ cơ bản.

Trinh sát cơ bản chưa thể phát hiện Bí mật.

Bí mật phù hợp với:

- đội trinh sát;
- thám báo;
- phục kích;
- các hoạt động quy mô nhỏ đặc biệt;
- một số lá bài tướng.

---

# 12. Nghi binh

Nghi binh là một hành động chiến tranh thông tin, không phải tin giả tự do.

Nghi binh chỉ được sử dụng khi đội hình có một mưu sĩ phù hợp.

Mưu sĩ:

- không cần trực tiếp dẫn đạo quân;
- chỉ cần có mặt trong đội hình và mở khóa kế sách.

Nghi binh cơ bản:

- gắn vào một hành động Hành quân;
- làm quy mô quan sát được của đạo quân tăng lên, ví dụ x3;
- không tạo thêm quân;
- không tăng sức mạnh chiến đấu;
- không thay đổi tổn thất thật;
- bị Trinh sát hợp lệ xác nhận quy mô thật.

Game không sử dụng hệ thống tin giả phức tạp trong chế độ cơ bản vì:

- dễ làm người chơi rối;
- khó cân bằng;
- có thể trở nên quá mạnh hoặc hài hước;
- tạo nhiều thao tác nhưng không tăng đủ chiều sâu.

---

# 13. Quân lương

## 13.1. Đơn vị

Đơn vị lương là **thạch lương thảo**.

Quy ước hiện tại:

> 1 thạch lương thảo nuôi được 100 quân trong 1 ngày.

Vì một lượt bằng 3 ngày:

```text
Lương cần trong 1 lượt
= số quân / 100 × 3
```

Ví dụ:

- 1.000 quân cần 30 thạch cho một lượt;
- 10.000 quân cần 300 thạch cho một lượt.

Các con số cân bằng cuối cùng có thể được điều chỉnh, nhưng mọi ví dụ phải tuân theo cùng một công thức.

## 13.2. Lương trong thành

Mỗi thành có:

- lương dự trữ;
- tốc độ sản xuất lương theo ngày;
- quân trú đóng;
- sĩ khí;
- khả năng thu thêm lương.

Mỗi lượt:

- thành sản xuất lương;
- quân trú đóng tiêu thụ lương;
- phần dư được đưa vào kho;
- nếu sản xuất và kho không đủ, thành thiếu lương.

Khi thành thiếu lương:

- sĩ khí thành giảm;
- thiếu càng lâu, sĩ khí giảm càng nhanh;
- khả năng chiêu binh và ổn định giảm;
- thành có thể tự hàng khi sĩ khí về 0.

Sản lượng thành giới hạn việc:

- chiêu binh vô hạn;
- giữ quá nhiều quân;
- mở nhiều chiến dịch cùng lúc.

## 13.3. Lương của doanh trại

Doanh trại không tự sản xuất lương.

Doanh trại chỉ có:

- lương dự trữ;
- quân trú đóng;
- sĩ khí.

Doanh trại phải được vận lương từ thành.

Nếu:

- tuyến lương bị cắt;
- doanh trại bị vây;
- đoàn vận lương bị cướp;
- người chơi không cứu viện;

doanh trại sẽ cạn lương và mất sĩ khí.

Người chơi phải lựa chọn:

- cứu viện;
- phá vây;
- mở lại tuyến;
- rút quân;
- hoặc chấp nhận mất doanh trại.

## 13.4. Lương của hành động

Khi một hành động có quân tham gia, game tự tính số lương cần.

Người chơi không tự nhập số lượt.

Ví dụ Hành quân có thể gồm:

- số lượt đi;
- số lượt duy trì;
- số lượt quay về.

Nếu đạo quân dựng trại tại điểm đến:

- giai đoạn quay về bị hủy;
- phần lương còn lại trở thành lương dự trữ của doanh trại;
- sau đó cần Vận lương để duy trì.

Nếu nguồn không đủ lương, hành động không thể được xác nhận.

Người chơi không phải chia khẩu phần theo ngày. Game chỉ yêu cầu người chơi cân nhắc:

- quân số;
- thời gian;
- lương cần;
- lương còn lại;
- rủi ro nếu chiến dịch kéo dài.

## 13.5. Lương tổng trên giao diện

Chỉ số lương ở góc trên là tổng lương của phe.

Tuy nhiên, lương vẫn tồn tại tại từng vị trí:

- kho thành;
- doanh trại;
- đoàn vận lương;
- phần lương đã dành cho một hành động.

Tổng lương giúp nhìn nhanh sức mạnh hậu cần, nhưng không thay thế vị trí thật của lương.

---

# 14. Sĩ khí

## 14.1. Sĩ khí riêng

Mỗi chủ thể có sĩ khí riêng:

- đạo quân;
- thành;
- doanh trại.

## 14.2. Sĩ khí trung bình toàn quân

Chỉ số sĩ khí ở góc trên là sĩ khí trung bình của toàn phe.

Chỉ số này giúp người chơi biết tình trạng chiến dịch tổng thể.

Nó không thay thế sĩ khí riêng của từng đơn vị.

## 14.3. Sĩ khí giảm khi

- thiếu lương;
- hành quân quá lâu;
- hành quân trong thời tiết xấu;
- bị phục kích;
- bị tập kích doanh trại;
- bị cướp lương;
- thua trận;
- bị vây;
- bị cắt tiếp tế;
- tướng bị thương hoặc mất;
- ở quá lâu trong tình trạng không có đường rút.

## 14.4. Sĩ khí tăng khi

- thắng trận;
- chiếm thành;
- phá vây;
- nhận được lương;
- sử dụng Mừng công;
- sử dụng lá bài tướng đặc biệt;
- được một số tướng hoặc nội thần hỗ trợ.

## 14.5. Sĩ khí về 0

### Đạo quân

- tan rã;
- đầu hàng;
- không thể tiếp tục chiến đấu;
- mệnh lệnh bị hủy;
- tướng có thể bị bắt, đào ngũ hoặc rút về tùy luật sau này.

### Thành

- tự hàng;
- đổi chủ nếu đang bị vây;
- có thể rơi vào hỗn loạn nếu không có phe chiếm.

### Doanh trại

- bị bỏ;
- quân tan rã hoặc đầu hàng;
- lương còn lại có thể bị thu giữ.

Game cho phép một bên thắng mà không cần giao chiến trực tiếp.

---

# 15. Địa hình

Địa hình thay đổi:

- tốc độ hành quân;
- quân số có thể đi qua;
- footprint có thể đặt;
- tổn thất;
- khả năng phục kích;
- khả năng phòng thủ;
- tuyến lương;
- khả năng bị vây.

## 15.1. Đồng bằng

- phù hợp với đại quân;
- hành quân nhanh;
- dễ bị quan sát;
- giao chiến trực diện phổ biến.

## 15.2. Rừng

- hỗ trợ trinh sát và phục kích;
- giảm tốc đại quân;
- che giấu hành động nhỏ tốt hơn.

## 15.3. Rừng rậm

- khó hành quân;
- tăng tiêu hao;
- khó tổ chức quân số lớn;
- thuận lợi cho phục kích nhỏ.

## 15.4. Núi hiểm

Ví dụ một vị trí có ba mặt núi:

- khó bị tập kích từ nhiều hướng;
- khó đưa đại quân qua;
- một lực lượng nhỏ có thể đi được nhưng 10.000 quân có thể không đi qua;
- dễ thủ, khó công;
- nếu lối ra duy nhất bị khóa thì dễ bị bao vây.

## 15.5. Sông và hồ

- có thể hỗ trợ hoặc cản vận lương;
- tạo điểm nghẽn;
- cần cầu, bến hoặc đường vòng;
- tạo lợi thế phòng thủ;
- tuyến vượt sông có thể bị phá.

---

# 16. Thời tiết

Người chơi biết trước thời tiết trong **7 lượt**.

Vì một lượt bằng 3 ngày, người chơi có thể nhìn trước khoảng 21 ngày chiến dịch.

Thời tiết là thông tin để lập kế hoạch, không phải ngẫu nhiên hoàn toàn mù.

## 16.1. Trời mưa

Ảnh hưởng đã định hướng:

- hành quân chậm hơn;
- tăng tiêu hao;
- giảm hiệu quả phục kích;
- tăng thiệt hại khi tập kích doanh trại;
- làm công thành giảm hiệu quả rất mạnh, có thể tới khoảng 90%;
- tăng áp lực hậu cần.

## 16.2. Sương mù

- tăng khả năng phục kích;
- tăng hiệu quả tập kích;
- giảm khả năng quan sát;
- hỗ trợ các hành động bí mật hoặc bán công khai.

## 16.3. Trời quang

- phù hợp với hành quân lớn;
- dễ quan sát;
- thuận lợi cho giao chiến trực diện;
- thuận lợi cho công thành hơn mưa.

Các loại thời tiết khác có thể được bổ sung sau.

---

# 17. Thiệt hại và giao chiến

Thiệt hại có hai loại lớn.

## 17.1. Tiêu hao không giao chiến

Quân có thể bị hao hụt vì:

- hành quân;
- mưa;
- núi;
- rừng rậm;
- bệnh;
- mệt mỏi;
- thiếu lương;
- bị cô lập.

Đây là tổn thất trước khi trận đánh thật sự bắt đầu.

## 17.2. Thiệt hại giao chiến

Kết quả trận đánh không chỉ dựa vào quân số.

Sức mạnh thực tế của một bên phụ thuộc vào:

- quân số;
- chất lượng quân;
- sĩ khí;
- tướng;
- thẻ bài;
- địa hình;
- thời tiết;
- công sự;
- trạng thái lương;
- phục kích hoặc bất ngờ;
- vị trí tấn công và phòng thủ.

Cả bên thắng và bên thua đều có thể mất quân.

Biên độ thắng quyết định:

- tổn thất quân;
- tổn thất sĩ khí;
- khả năng rút quân;
- khả năng truy kích;
- nguy cơ tan rã.

Công thức số cụ thể chưa khóa.

---

# 18. Mười hai lá bài cơ bản

## 18.1. Hành quân

Cho phép một đạo quân di chuyển từ vị trí hiện tại tới một mục tiêu.

Yêu cầu:

- chọn tướng;
- chọn quân số;
- chọn nguồn;
- chọn đích.

Game tự tính:

- đường đi;
- số lượt;
- lương cần;
- tác động địa hình;
- tác động thời tiết;
- mức lộ diện.

Hành quân cơ bản là Công khai.

Đối phương thấy:

- nguồn;
- tiến trình;
- vị trí hiện tại.

Đối phương không thấy đích.

Nếu đến nơi mà không Dựng trại hoặc nhận lệnh mới, đạo quân có thể quay về theo kế hoạch hành động.

## 18.2. Dựng trại

Biến vị trí hiện tại của đạo quân thành một doanh trại.

Dựng trại:

- dừng kế hoạch quay về;
- tạo footprint theo quân số;
- chuyển lương còn lại vào kho trại;
- cho phép vận lương tới;
- tạo một điểm tựa tiền tuyến.

Doanh trại không sản xuất lương.

## 18.3. Rút quân

Cho phép đạo quân hoặc doanh trại rời vị trí hiện tại và quay về:

- thành phe mình;
- doanh trại phe mình;
- hoặc một vị trí an toàn hợp lệ.

Rút quân vẫn mất thời gian và lương.

Không phải teleport.

## 18.4. Thu lương

Dùng tại một thành để tăng lương dự trữ.

Hiệu quả phụ thuộc:

- quy mô thành;
- sản lượng;
- dân tình;
- sĩ khí;
- tướng;
- lá bài tướng;
- hoàn cảnh chiến dịch.

Thu lương là hành động Bán công khai.

Nếu thành nằm trong phạm vi trinh sát của đối phương, hành động bị lộ.

## 18.5. Vận lương

Chuyển lương từ một thành nguồn tới:

- thành khác;
- doanh trại;
- đạo quân;
- hoặc điểm chiến dịch hợp lệ.

Đoàn vận lương có:

- lương hàng hóa;
- quân hộ tống;
- thời gian di chuyển;
- tuyến đường;
- nguy cơ bị trinh sát, phục kích và cướp.

Vận lương cơ bản được xem là Công khai trong tutorial.

## 18.6. Mừng công

Dùng sau:

- chiến thắng;
- chiếm thành;
- phá vây;
- hoặc một sự kiện đủ điều kiện.

Tác dụng:

- tăng sĩ khí;
- ổn định quân hoặc thành;
- tiêu tốn lương.

Mừng công cơ bản không nhất thiết hồi tối đa.

## 18.7. Trinh sát

Đặt một nhóm trinh sát tại một ô.

- footprint 1x1;
- phạm vi quan sát 5x5;
- hành động Bí mật;
- phát hiện hành động Bán công khai đi qua vùng quan sát;
- chưa phát hiện hành động Bí mật trong chế độ cơ bản.

## 18.8. Thám báo

Một đội trinh sát di động.

- di chuyển theo tuyến;
- phạm vi quan sát nhỏ hơn Trinh sát cố định;
- phù hợp dò sâu;
- tồn tại ngắn hơn;
- hành động Bí mật.

## 18.9. Phục kích

Bố trí quân theo đội hình hai cánh.

Footprint cơ bản:

```text
A A
. .
A A
```

Phục kích:

- là hành động Bí mật;
- có hướng đặt;
- kích hoạt khi quân địch đi vào vùng ảnh hưởng;
- chịu ảnh hưởng lớn bởi địa hình và thời tiết;
- không thể đặt như một khối vuông lớn tùy ý.

## 18.10. Vây thành

Đưa quân bao quanh một hoặc nhiều mặt của thành.

Tác dụng:

- cắt đường lương;
- giảm sĩ khí;
- ép thành tiêu hao dự trữ;
- ngăn tiếp viện;
- tạo điều kiện khuyên hàng hoặc công thành.

Quân vây cũng tiêu hao lương.

Vây thành là Công khai.

## 18.11. Công thành

Tấn công trực tiếp vào thành.

Kết quả phụ thuộc:

- quân số;
- sĩ khí;
- thành lũy;
- địa hình;
- hướng tấn công;
- thời tiết;
- mức độ vây;
- tướng;
- các lá bài.

Mưa làm hiệu quả công thành giảm rất mạnh.

Công thành là Công khai.

## 18.12. Nghi binh

Một kế sách gắn với hành động Hành quân.

Điều kiện:

- đội hình có mưu sĩ mở khóa;
- mưu sĩ không cần trực tiếp dẫn quân.

Tác dụng cơ bản:

- làm đối phương thấy quy mô lớn hơn thật;
- không tạo quân thật;
- không tăng sức chiến đấu;
- có thể bị Trinh sát bóc tách.

---

# 19. Vòng chơi một lượt

Một lượt gồm bốn phần.

## 19.1. Lập mệnh lệnh

Người chơi:

- xem bản đồ;
- xem thời tiết;
- xem bài trên tay;
- chọn thẻ;
- chọn chủ thể;
- chọn tướng;
- chọn quân;
- chọn vị trí;
- xem thời gian và lương;
- xác nhận.

## 19.2. Chốt lượt

Khi người chơi xác nhận kết thúc lượt:

- các mệnh lệnh mới bắt đầu;
- các mệnh lệnh cũ tiếp tục;
- các tướng bị khóa theo nhiệm vụ.

## 19.3. Giải quyết

Game cập nhật:

- tiến trình hành quân;
- sản xuất lương;
- tiêu thụ lương;
- vận lương;
- trinh sát;
- phát hiện;
- phục kích;
- vây thành;
- sĩ khí;
- tổn thất;
- các hành động hoàn thành.

## 19.4. Báo cáo quân tình

Người chơi nhận thông tin ngắn và trực quan:

- đạo quân đã đi được bao xa;
- lương thành còn bao nhiêu;
- trại còn đủ lương mấy lượt;
- hành động địch bị phát hiện;
- thành đang mất sĩ khí;
- quân đang gần tan rã;
- mệnh lệnh hoàn thành.

---

# 20. PvE và tutorial

PvE là điểm bắt đầu của người chơi.

Năm màn PvE đầu tiên là tutorial.

Mục tiêu:

- dạy bằng tình huống;
- không dồn tất cả hệ thống cùng lúc;
- mỗi màn tập trung vào một hoặc hai bài học;
- cho phép thất bại mềm;
- không yêu cầu đọc quá nhiều văn bản.

## 20.1. Màn 1 — Quân khởi binh

Dạy:

- chọn thẻ;
- chọn chủ thể;
- thu lương;
- chiêu quân hoặc sử dụng quân có sẵn;
- hành quân tới một mục tiêu gần;
- chiếm một thành nhỏ.

## 20.2. Màn 2 — Hành quân và vị trí

Dạy:

- tướng có vị trí thật;
- hành quân tốn thời gian;
- địa hình thay đổi tốc độ;
- dựng trại;
- rút quân.

## 20.3. Màn 3 — Lương thảo và sĩ khí

Dạy:

- thành có sản lượng và kho;
- quân tiêu thụ lương;
- doanh trại không tự sản xuất;
- phải vận lương;
- thiếu lương làm sĩ khí giảm;
- thắng trận vẫn có thể thua chiến dịch.

## 20.4. Màn 4 — Thông tin và trinh sát

Dạy:

- Công khai;
- Bán công khai;
- Bí mật;
- Trinh sát 5x5;
- Thám báo;
- phát hiện vệt hành quân;
- tránh phục kích.

## 20.5. Màn 5 — Chiến tranh thật sự

Dạy:

- phối hợp Chiến tướng, Mưu sĩ và Nội thần;
- sử dụng nhiều tuyến;
- cắt lương;
- vây thành;
- làm địch mất sĩ khí;
- thắng mà không cần tiêu diệt toàn bộ.

Kịch bản chi tiết theo lượt của từng màn chưa được khóa.

---

# 21. PvP

PvP sử dụng cùng hệ thống lõi với PvE.

Mục tiêu thiết kế:

- sâu nhưng dễ tiếp cận;
- không sử dụng xác suất thông tin quá phức tạp;
- không buộc người chơi quản lý khẩu phần vi mô;
- chiến thắng dựa trên kế hoạch, hậu cần, thông tin và phối hợp tướng;
- không chỉ dựa vào quân số.

Các yếu tố quan trọng trong PvP:

- đọc hướng hành quân;
- bảo vệ tuyến lương;
- dùng trinh sát đúng nơi;
- dùng nghi binh đúng lúc;
- khiến đối phương phải phản ứng;
- chiếm hoặc bỏ thành hợp lý;
- ép đối phương mất sĩ khí;
- tránh chiến dịch kéo dài quá khả năng hậu cần.

Nhịp độ và điều kiện thắng PvP cuối cùng chưa khóa.

---

# 22. Chế độ khó

## 22.1. Normal

Đây là chế độ chính.

Đặc điểm:

- sâu nhưng dễ tiếp cận;
- dành cho người mới;
- dùng trong PvE cốt truyện;
- phù hợp PvP;
- sai lầm có thể sửa;
- hậu cần quan trọng nhưng không quá trừng phạt.

## 22.2. Nightmare

Đây là nội dung mở rộng làm sau.

Đặc điểm:

- chậm;
- nặng;
- hardcore;
- tiêu hao cao;
- sai lầm khó cứu;
- phù hợp phó bản, kịch bản hoặc chiến dịch đặc biệt;
- không dùng làm chuẩn cân bằng PvP ban đầu.

---

# 23. Cảm giác người chơi mục tiêu

Game cần tạo cảm giác:

- mỗi mệnh lệnh đều có giá;
- một quyết định sai có thể gây hậu quả vài lượt sau;
- nhìn thấy quân đang di chuyển trên bản đồ;
- cảm nhận một chiến dịch đang sống;
- chiến thắng đến từ tổ chức;
- hậu cần là một chiến thuật thật;
- thông tin là một loại sức mạnh;
- thành trì và địa hình có ý nghĩa;
- tướng không chỉ là chỉ số;
- không cần tiêu diệt hết quân địch để thắng.

Game không hướng tới:

- thao tác nhanh;
- spam quân;
- quân vô hạn;
- thẻ bài tạo hiệu ứng phép thuật không liên quan chiến tranh;
- chiến thắng chỉ nhờ một tướng mạnh;
- quản lý vi mô khẩu phần từng đạo quân mỗi lượt;
- hệ tin giả quá phức tạp.

---

# 24. Những nội dung đã chốt

- Game thẻ bài chiến thuật theo lượt, bối cảnh chiến tranh vũ khí lạnh.
- Người chơi là Tổng chỉ huy.
- Mỗi trận chọn 10 tướng.
- Có ba loại tướng: Chiến tướng, Mưu sĩ, Nội thần.
- Mỗi tướng có nội tại và ba lá bài riêng.
- Có 12 lá bài cơ bản.
- Người chơi có 10 lá bài trên tay.
- Lá tướng được thêm vào card pool và có tỷ lệ rút.
- Một lượt bằng 3 ngày.
- Tướng có vị trí thật.
- Hành động có thể kéo dài nhiều lượt.
- Bản đồ tutorial là 16x16.
- Thành có footprint nhiều ô.
- Trinh sát chiếm 1x1, ảnh hưởng 5x5.
- Doanh trại khoảng 2.000 quân mỗi ô.
- Phục kích có đội hình hai hàng 1x2 cách nhau một hàng.
- Có ba mức thông tin: Công khai, Bán công khai, Bí mật.
- Công khai không lộ điểm đến.
- Bán công khai cần trinh sát để phát hiện.
- Bí mật chưa bị trinh sát cơ bản phát hiện.
- Nghi binh cần mưu sĩ nhưng mưu sĩ không cần dẫn quân.
- Lương dùng đơn vị thạch.
- 1 thạch nuôi 100 quân trong 1 ngày.
- Thành có kho và tốc độ sản xuất lương.
- Doanh trại không sản xuất lương.
- Thiếu lương làm giảm sĩ khí.
- Sĩ khí tồn tại riêng ở thành, trại và đạo quân.
- Sĩ khí HUD là sĩ khí trung bình toàn quân.
- Sĩ khí bằng 0 có thể dẫn tới đầu hàng hoặc tan rã.
- Người chơi biết trước thời tiết 7 lượt.
- Normal là chế độ chính.
- Nightmare là nội dung mở rộng sau.
- Năm màn PvE đầu tiên là tutorial.

---

# 25. Những nội dung chưa khóa

Các nội dung sau cần tiếp tục thiết kế:

- năng lượng ban đầu, tốc độ tăng và mức tối đa;
- tỷ lệ rút từng loại bài;
- kích thước bộ bài và cơ chế bỏ bài;
- số bản sao của mỗi lá cơ bản;
- chi tiết từng lá bài tướng;
- công thức thời gian của từng hành động;
- thời gian duy trì Hành quân;
- tốc độ từng loại quân;
- footprint của đạo quân đang hành quân;
- giới hạn kích thước doanh trại;
- công thức Thu lương;
- công thức Chiêu binh;
- chi phí Mừng công;
- công thức giảm sĩ khí do thiếu lương;
- công thức giao chiến;
- công thức tiêu hao;
- luật truy kích;
- luật đào ngũ hoặc bắt tướng;
- công thức Vây thành;
- công thức Công thành;
- điều kiện Khuyên hàng;
- điều kiện thắng/thua PvP;
- kịch bản chi tiết năm màn tutorial;
- hệ AI PvE;
- các loại thời tiết bổ sung;
- chất lượng quân và binh chủng;
- quan hệ giữa nhiều đạo quân trong cùng một ô hoặc khu vực.

---

# 26. Nguyên tắc phát triển nội dung tiếp theo

Khi bổ sung hệ thống mới, cần giữ các nguyên tắc:

1. Hệ thống phải tạo quyết định chiến thuật thật.
2. Không thêm vi mô nếu không tạo thêm chiều sâu.
3. Người chơi phải nhìn thấy được tác động của quyết định.
4. Tướng phải thay đổi cách chơi, không chỉ cộng phần trăm.
5. Lá bài tướng nên dựa trên nền của lá cơ bản.
6. Thông tin phải rõ điều kiện, hạn chế RNG mù.
7. Hậu cần phải quan trọng nhưng thao tác phải gọn.
8. Một sai lầm phải có hậu quả, nhưng Normal vẫn cho cơ hội sửa.
9. Bản đồ phải là một phần của gameplay, không chỉ là nền.
10. PvE phải dạy người chơi trước khi đưa họ vào PvP.

---

# 27. Tóm tắt một câu

> Đây là game thẻ bài chiến thuật theo lượt, nơi người chơi dùng tướng và mệnh lệnh để điều hành một chiến dịch chiến tranh; chiến thắng đến từ việc phối hợp quân số, lương thảo, sĩ khí, địa hình, thời tiết và thông tin — chứ không chỉ từ việc có quân mạnh hơn.
