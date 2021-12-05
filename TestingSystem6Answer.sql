USE Testingsystem3;
-- Question 1: Tạo store để người dùng nhập vào tên phòng ban và in ra tất cả các account thuộc phòng ban đó
DELIMITER $$
	CREATE PROCEDURE get_account_by_department(IN in_departmentName VARCHAR(100))
		BEGIN
			SELECT 
				a.Email, a.Username, a.FullName, b.departmentName
			FROM
				account a
				INNER JOIN department b ON a.DepartmentID = b.DepartmentID
			WHERE 
				b.departmentName = in_departmentName;
        END $$
DELIMITER ;


-- Q2: Tạo store để in ra số lượng account trong mỗi group
DELIMITER $$
	CREATE PROCEDURE question2()
    BEGIN	
		SELECT 
			a.GroupName, count(b.AccountID) AS total_employee
		FROM 
			`group` a
			LEFT JOIN groupaccount b ON a.GroupID = b.GroupID
		GROUP BY 
			a.GroupID;
    END $$
DELIMITER ;

CALL question2();


-- Q3: Tạo store để thống kê mỗi type question có bao nhiêu question được tạo trong tháng hiện tại
DELIMITER $$
CREATE PROCEDURE get_count_typeQuestion(IN in_type_name VARCHAR(100)) 
	BEGIN
		SELECT 
			b.TypeName, count(a.QuestionID)
		FROM
			question a
			LEFT JOIN typequestion b ON a.TypeID = b.TypeID
		WHERE 
			YEAR(a.CreateDate) = 2020
			AND MONTH(a.CreateDate) = MONTH(sysdate()) 
            AND b.TypeName = in_type_name
		GROUP BY
			b.TypeName;
    END$$
DELIMITER ;


-- Q4: Tạo store để trả ra id của type question có nhiều câu hỏi nhất
DELIMITER $$
	CREATE PROCEDURE question4()
    BEGIN	
			SELECT 
				a.TypeID, a.TypeName, count(b.QuestionID) AS total
			FROM
				typequestion a
				LEFT JOIN question b ON a.TypeID = b.TypeID
			GROUP BY
				a.TypeID, a.TypeName
			ORDER BY
				total DESC LIMIT 1;
    END $$
DELIMITER ;

CALL question4();

-- Q5: đã trả ra luôn TypeName ở Câu 4

-- Q6: Viết 1 store cho phép người dùng nhập vào 1 chuỗi và trả về group có tên
-- chứa chuỗi của người dùng nhập vào hoặc trả về user có username chứa
-- chuỗi của người dùng nhập vào

DROP PROCEDURE question6;

DELIMITER $$
	CREATE PROCEDURE question6(IN in_text_input VARCHAR(150))
    BEGIN	
			SELECT 'Group', GroupName FROM `group` WHERE GroupName LIKE CONCAT('%',in_text_input,'%')
			UNION ALL 
			SELECT 'Username', Username FROM account WHERE Username LIKE CONCAT('%',in_text_input,'%');
    END $$
DELIMITER ;

CALL question6('ment');


-- Q7: Viết 1 store cho phép người dùng nhập vào thông tin fullName, email và trong store sẽ tự động gán:
-- username sẽ giống email nhưng bỏ phần @..mail đi
-- positionID: sẽ có default là developer
-- departmentID: sẽ được cho vào 1 phòng chờ
-- Sau đó in ra kết quả tạo thành công

-- > Full name: Tạ Minh Thuấn
-- > email:  minhthuan.ta0502@gmail.com => minhthuan.ta0502
SELECT SUBSTRING("minhthuan.ta0502@gmail.com", 1, POSITION("@" IN "minhthuan.ta0502@gmail.com") - 1);
SELECT SUBSTRING(in_email, 1, POSITION("@" IN in_email) - 1);

DELIMITER $$
	CREATE PROCEDURE question7(IN in_fullName VARCHAR(150), IN in_email VARCHAR(200))
    BEGIN
			-- Khởi tạo biến username
			DECLARE temp_username VARCHAR(200);
			
			-- Get ra username từ email
			SELECT SUBSTRING(in_email, 1, POSITION("@" IN in_email) - 1) INTO temp_username;
			
			-- Câu lệnh insert chính
			INSERT INTO account(Email, Username, FullName, DepartmentID, PositionID, CreateDate)
								VALUES (in_email, temp_username, in_fullName, 1, 1, now());
			
			-- In kết quả sau khi tạo thành công:
			SELECT * FROM account WHERE email = in_email AND FullName = in_fullName;
    END $$
DELIMITER ;

CALL question7("Bùi Phương Thảo","thaobp1026@gmail.com");

-- Q8: Viết 1 store cho phép người dùng nhập vào Essay hoặc Multiple-Choice
-- để thống kê câu hỏi essay hoặc multiple-choice nào có content dài nhất
DELIMITER $$
	CREATE PROCEDURE question8(IN in_type_questiton VARCHAR(100))
    BEGIN	
				SELECT content 
				FROM question a 
				LEFT JOIN typequestion b ON a.TypeID = b.TypeID
				WHERE 
					b.TypeName = in_type_questiton
					AND
					LENGTH(a.Content) = ( SELECT
															LENGTH(a.Content)
														FROM 
															question a
															LEFT JOIN typequestion b ON a.TypeID = b.TypeID
														WHERE 
																b.TypeName = in_type_questiton
														ORDER BY 
																LENGTH(a.Content) DESC Limit 1);
    END $$
DELIMITER ;

CALL question8('Essay');
CALL question8('Multiple-Choice');

-- Q9: Viết 1 store cho phép người dùng xóa exam dựa vào ID
DELIMITER $$
	CREATE PROCEDURE question9(IN in_examID INT)
    BEGIN	
		-- xoa trong examquestion
		DELETE FROM examquestion WHERE ExamID = in_examID;
		
		-- xoa trong exam
		DELETE FROM exam WHERE ExamID = in_examID;		
    END $$
DELIMITER ;

CALL question9(4);


-- Q10: Tìm ra các exam được tạo từ 3 năm trước và xóa các exam đó đi (sử
-- dụng store ở câu 9 để xóa)
-- Sau đó in số lượng record đã remove từ các table liên quan trong khi removing
SELECT ExamID FROM exam WHERE CreateDate < '2020-04-06';

DROP PROCEDURE question10;

DELIMITER $$
	CREATE PROCEDURE question10()
    BEGIN	
		DECLARE deleted_examquestion, deleted_exam INT;
		-- đếm số lượng sẽ xóa:
		SELECT COUNT(*) INTO deleted_examquestion FROM examquestion WHERE ExamID IN (SELECT ExamID FROM exam WHERE CreateDate < '2020-04-06');
		SELECT COUNT(*) INTO deleted_exam FROM exam WHERE ExamID IN (SELECT ExamID FROM exam WHERE CreateDate < '2020-04-06');
		
		-- xoa trong examquestion
		DELETE FROM examquestion WHERE ExamID IN (SELECT ExamID FROM exam WHERE CreateDate < '2020-04-06');
		
		-- xoa trong bang exam 
		WITH exam_temp AS (SELECT ExamID FROM exam WHERE CreateDate < '2020-04-06') 
		DELETE FROM exam WHERE ExamID IN (SELECT ExamID FROM exam_temp);		
		
		-- In ra kết quả số lượng bản ghi đã xóa
		SELECT 'Deleted Examquestion', deleted_examquestion FROM dual 
		UNION
		SELECT 'Deleted Exam', deleted_exam FROM dual; 
				
    END $$
DELIMITER ;

CALL question10();


-- Q11: Viết store cho phép người dùng xóa phòng ban bằng cách người dùng
-- nhập vào tên phòng ban và các account thuộc phòng ban đó sẽ được
-- chuyển về phòng ban default là phòng ban chờ việc

DELIMITER $$
	CREATE PROCEDURE question11(IN in_Department_Name VARCHAR(100))
    BEGIN	
			-- Update các account thuộc phòng ban cần xóa về phòng ban default (13)
			UPDATE account SET DepartmentID = 13 WHERE DepartmentID = (SELECT DepartmentID FROM department WHERE DepartmentName = in_Department_Name);
			
			-- Xóa phòng ban:
			DELETE FROM department WHERE DepartmentName = in_Department_Name;
    END $$
DELIMITER ;

CALL question11('Services');


-- Q12: Viết store để in ra mỗi tháng có bao nhiêu câu hỏi được tạo trong năm nay
DELIMITER $$
	CREATE PROCEDURE question12()
    BEGIN	
				SELECT 2021 AS YEAR, MONTH(CreateDate), count(QuestionID) 
				FROM question WHERE YEAR(CreateDate) = 2021 GROUP BY MONTH(CreateDate);
    END $$
DELIMITER ;


CALL question12();

-- Q13: Viết store để in ra mỗi tháng có bao nhiêu câu hỏi được tạo trong 6 tháng gần đây nhất
-- (Nếu tháng nào không có thì sẽ in ra là "không có câu hỏi nào trong tháng")

SELECT 
	a.year_c, a.month_c, 
	CASE WHEN b.total > 0 THEN b.total ELSE "Không có câu nào trong tháng" END AS total
FROM
(SELECT YEAR(SYSDATE()) AS year_c, MONTH(sysdate()) AS month_c
UNION
SELECT YEAR(SYSDATE() - interval 1 month), MONTH(sysdate() - interval 1 month)
UNION
SELECT YEAR(SYSDATE() - interval 2 month), MONTH(sysdate() - interval 2 month)
UNION
SELECT YEAR(SYSDATE() - interval 3 month), MONTH(sysdate() - interval 3 month)
UNION
SELECT YEAR(SYSDATE() - interval 4 month), MONTH(sysdate() - interval 4 month)
UNION
SELECT YEAR(SYSDATE() - interval 5 month), MONTH(sysdate() - interval 5 month)) a
LEFT JOIN (
	SELECT
	YEAR(CreateDate) as year_q,
	MONTH(CreateDate) as month_q,
	count(QuestionID) As total
FROM 
	question
GROUP BY
	YEAR(CreateDate),
	MONTH(CreateDate)
) b ON a.year_c = b.year_q AND a.month_c = b.month_q


