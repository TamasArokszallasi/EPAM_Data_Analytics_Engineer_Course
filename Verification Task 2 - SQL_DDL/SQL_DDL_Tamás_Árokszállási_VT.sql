--Task 1

CREATE TABLE public.Institutions (
    InstitutionID INT PRIMARY KEY,
    Name VARCHAR(100) NOT NULL,
    Location VARCHAR(100) NOT NULL,
    Staff INT NOT NULL CHECK (Staff > 0),
    Resources INT NOT NULL CHECK (Resources > 0),
    Capabilities INT NOT NULL CHECK (Capabilities > 0)
);


CREATE TABLE public.Departments (
    DepartmentID INT PRIMARY KEY,
    InstitutionID INT,
    Name VARCHAR(100) NOT NULL,
    FOREIGN KEY (InstitutionID) REFERENCES Institutions(InstitutionID)
);


CREATE TABLE public.Staff (
    StaffID INT PRIMARY KEY,
    Name VARCHAR(100) NOT NULL,
    Position VARCHAR(50) NOT null check (position in ('Doctor', 'Assitant', 'Nurse')),
    DepartmentID INT,
    FOREIGN KEY (DepartmentID) REFERENCES Departments(DepartmentID)
);

CREATE TABLE public.Patients (
    PatientID INT PRIMARY KEY,
    Name VARCHAR(100) NOT NULL,
    Age INT NOT NULL CHECK (Age > 0),
    Gender CHAR(1) CHECK (Gender IN ('M', 'F')),
    InstitutionID INT,
    FOREIGN KEY (InstitutionID) REFERENCES Institutions(InstitutionID)
);


CREATE TABLE public.Visits (
    VisitID INT PRIMARY KEY,
    PatientID INT,
    DepartmentID INT,
    VisitDate DATE DEFAULT CURRENT_DATE,
    FOREIGN KEY (PatientID) REFERENCES Patients(PatientID),
    FOREIGN KEY (DepartmentID) REFERENCES Departments(DepartmentID)
   
);

CREATE TABLE public.PatientRecords (
    RecordID INT PRIMARY KEY,
    VisitID INT,
    StaffID INT,
    Diagnosis VARCHAR(255),
    Treatment VARCHAR(255),
    FOREIGN KEY (VisitID) REFERENCES Visits(VisitID),
    FOREIGN KEY (StaffID) REFERENCES Staff(StaffID)
);

CREATE TABLE public.Resources (
    ResourceID INT PRIMARY KEY,
    DepartmentID INT,
    ResourceType VARCHAR(50) NOT NULL,
    Quantity INT NOT NULL CHECK (Quantity > 0),
    FOREIGN KEY (DepartmentID) REFERENCES Departments(DepartmentID));
   
INSERT INTO public.Institutions (InstitutionID, Name, Location, Staff, Resources, Capabilities)
VALUES 
(1, 'City Hospital', '123 Main St', 100, 50, 200),
(2, 'Green Clinic', '456 Oak Rd', 50, 30, 100),
(3, 'Sunshine Medical Center', '789 Pine Ave', 150, 70, 300),
(4, 'Moonlight Health Facility', '321 Star Blvd', 80, 40, 160),
(5, 'Rainbow Rehabilitation', '654 Rainbow Ln', 60, 35, 120);


INSERT INTO public.Departments (DepartmentID, InstitutionID, Name)
VALUES 
(1, 1, 'Cardiology'),
(2, 1, 'Neurology'),
(3, 2, 'Pediatrics'),
(4, 2, 'Dermatology'),
(5, 3, 'Orthopedics'),
(6, 3, 'Radiology'),
(7, 4, 'Gastroenterology'),
(8, 4, 'Endocrinology'),
(9, 5, 'Psychiatry'),
(10, 5, 'Ophthalmology');


INSERT INTO public.Staff (StaffID, DepartmentID, Name, Position)
VALUES 
(1, 1, 'Dr. Smith', 'Doctor'),
(2, 1, 'Nurse Johnson', 'Nurse'),
(3, 2, 'Dr. Brown', 'Doctor'),
(4, 2, 'Nurse Davis', 'Nurse'),
(5, 3, 'Dr. Miller', 'Doctor');


INSERT INTO public.Patients (PatientID, Name, Age, Gender, InstitutionID)
VALUES 
(1, 'John Doe', 30, 'M', 1),
(2, 'Jane Smith', 25, 'F', 2),
(3, 'Bob Johnson', 35, 'M', 3),
(4, 'Alice Davis', 40, 'F', 4),
(5, 'Charlie Brown', 45, 'M', 5);

INSERT INTO public.Visits (VisitID, PatientID, DepartmentID)
VALUES 
(1, 1, 1),
(2, 2, 3),
(3, 3, 5),
(4, 4, 7),
(5, 5, 9);

INSERT INTO public.PatientRecords (RecordID, VisitID, Diagnosis, Treatment)
VALUES 
(1, 1, 'High blood pressure', 'Medication'),
(2, 2, 'Flu', 'Rest and hydration'),
(3, 3, 'Broken arm', 'Cast'),
(4, 4, 'Stomach ache', 'Diet changes'),
(5, 5, 'Eye strain', 'Rest and eye drops');

INSERT INTO public.Resources (ResourceID, DepartmentID, ResourceType, Quantity)
VALUES 
(1, 1, 'ECG Machine', 2),
(2, 2, 'MRI Scanner', 1),
(3, 3, 'Pediatric Beds', 10),
(4, 4, 'Dermatoscope', 3),
(5, 5, 'Orthopedic Beds', 8);

--Task 2

SELECT s.Name
FROM public.Staff s
WHERE s.Position = 'Doctor' AND s.DepartmentID NOT IN (
    SELECT v.DepartmentID
    FROM public.Visits v
    WHERE v.VisitDate BETWEEN (CURRENT_DATE - INTERVAL '2 months') AND CURRENT_DATE
    GROUP BY v.DepartmentID
    HAVING COUNT(v.PatientID) >= 5
);

