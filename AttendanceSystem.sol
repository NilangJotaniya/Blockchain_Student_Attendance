// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0; 

contract Attendance {
    address public owner;

    struct AttendanceRecord {
        uint256 date;        // format: YYYYMMDD (e.g., 20251007)
        bool present;        // true => Present, false => Absent
        address teacher;     // who marked
        uint256 timestamp;   // block timestamp when recorded
        string course;       // course or class identifier
        uint256 blockNumber; // block number when recorded
    }

    // registered teachers and students
    mapping(address => bool) public isTeacher;
    mapping(address => bool) public isStudent;

    // optional student metadata (e.g., roll number)
    mapping(address => string) public studentRoll;

    // student => attendance array
    mapping(address => AttendanceRecord[]) private attendances;

    // events
    event TeacherAdded(address indexed teacher);
    event TeacherRemoved(address indexed teacher);
    event StudentRegistered(address indexed student, string roll);
    event AttendanceMarked(address indexed student, uint256 indexed date, bool present, address indexed teacher, string course);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    modifier onlyTeacher() {
        require(isTeacher[msg.sender], "Only authorized teacher");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    /// @notice Owner adds a teacher address
    function addTeacher(address _teacher) external onlyOwner {
        require(_teacher != address(0), "zero address");
        require(!isTeacher[_teacher], "already teacher");
        isTeacher[_teacher] = true;
        emit TeacherAdded(_teacher);
    }

    /// @notice Owner removes a teacher address
    function removeTeacher(address _teacher) external onlyOwner {
        require(isTeacher[_teacher], "not a teacher");
        isTeacher[_teacher] = false;
        emit TeacherRemoved(_teacher);
    }

    /// @notice Owner registers a student with optional roll string
    function registerStudent(address _student, string calldata _roll) external onlyOwner {
        require(_student != address(0), "zero address");
        require(!isStudent[_student], "already student");
        isStudent[_student] = true;
        studentRoll[_student] = _roll;
        emit StudentRegistered(_student, _roll);
    }

    /// @notice Teacher marks attendance for a student
    /// @param _student the student's address
    /// @param _date date as YYYYMMDD (e.g., 20251007)
    /// @param _present true if present, false if absent
    /// @param _course short course/class identifier
    function markAttendance(
        address _student,
        uint256 _date,
        bool _present,
        string calldata _course
    ) external onlyTeacher {
        require(isStudent[_student], "student not registered");
        AttendanceRecord memory rec = AttendanceRecord({
            date: _date,
            present: _present,
            teacher: msg.sender,
            timestamp: block.timestamp,
            course: _course,
            blockNumber: block.number
        });
        attendances[_student].push(rec);
        emit AttendanceMarked(_student, _date, _present, msg.sender, _course);
    }

    /// @notice Get number of attendance records for a student
    function getAttendanceCount(address _student) external view returns (uint256) {
        return attendances[_student].length;
    }

    /// @notice Get a specific attendance record by index for a student
    /// @dev index is 0-based (0 => first recorded)
    function getAttendanceByIndex(address _student, uint256 _index)
        external
        view
        returns (
            uint256 date,
            bool present,
            address teacher,
            uint256 timestamp,
            string memory course,
            uint256 blockNumber
        )
    {
        require(_index < attendances[_student].length, "index out of bounds");
        AttendanceRecord storage r = attendances[_student][_index];
        return (r.date, r.present, r.teacher, r.timestamp, r.course, r.blockNumber);
    }

    /// @notice Check if an address is a teacher
    function checkIsTeacher(address _addr) external view returns (bool) {
        return isTeacher[_addr];
    }

    /// @notice Check if an address is a registered student
    function checkIsStudent(address _addr) external view returns (bool) {
        return isStudent[_addr];
    }

    /// @notice Owner can transfer ownership
    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "zero address");
        owner = _newOwner;
    }
}
