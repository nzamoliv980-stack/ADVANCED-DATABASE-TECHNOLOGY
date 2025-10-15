-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Oct 15, 2025 at 08:42 PM
-- Server version: 10.4.28-MariaDB
-- PHP Version: 8.2.4

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `cms`
--

-- --------------------------------------------------------

--
-- Table structure for table `contractor`
--

CREATE TABLE `contractor` (
  `ContractorID` int(11) NOT NULL,
  `Name` varchar(50) NOT NULL,
  `Contact` varchar(20) NOT NULL,
  `Company` varchar(100) NOT NULL,
  `ExperienceYears` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `contractor`
--

INSERT INTO `contractor` (`ContractorID`, `Name`, `Contact`, `Company`, `ExperienceYears`) VALUES
(1, 'John kenned', '0788509213', 'horizon', 10),
(2, 'KAYITARE Aman', '0788563354', 'NPD', 15),
(3, 'RWAGASORE', '0780694975', 'CWC Rwanda', 5);

-- --------------------------------------------------------

--
-- Table structure for table `equipment`
--

CREATE TABLE `equipment` (
  `EquipmentID` int(11) NOT NULL,
  `ProjectID` int(11) DEFAULT NULL,
  `Name` varchar(200) DEFAULT NULL,
  `CostPerDay` float NOT NULL,
  `Status` varchar(50) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `expense`
--

CREATE TABLE `expense` (
  `ExpenseID` int(11) NOT NULL,
  `ProjectID` int(11) DEFAULT NULL,
  `Description` varchar(250) DEFAULT NULL,
  `Amount` float(10,2) NOT NULL,
  `Exp_Date` date NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `expense`
--

INSERT INTO `expense` (`ExpenseID`, `ProjectID`, `Description`, `Amount`, `Exp_Date`) VALUES
(1, 2, 'Dam for power, irrigation, drinking water. Aims to serve both Rwanda and Burundi.', 38.00, '2025-12-31'),
(2, 3, 'Hydropower to generate 80MW accross the Kagera river, shared by regions Rwanda, tanzania and Burundi.', 25.00, '2030-12-31');

--
-- Triggers `expense`
--
DELIMITER $$
CREATE TRIGGER `check_project_budget` BEFORE INSERT ON `expense` FOR EACH ROW BEGIN
    DECLARE total_expenses DECIMAL(10,2);
    DECLARE project_budget DECIMAL(10,2);

    -- Sum existing expenses for this project
    SELECT IFNULL(SUM(Amount), 0)
    INTO total_expenses
    FROM Expense
    WHERE ProjectID = NEW.ProjectID;

    -- Get project budget
    SELECT Budget
    INTO project_budget
    FROM Project
    WHERE ProjectID = NEW.ProjectID;

    -- Prevent exceeding budget
    IF (total_expenses + NEW.Amount) > project_budget THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Total expenses exceed the project budget.';
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `material`
--

CREATE TABLE `material` (
  `MaterialID` int(11) NOT NULL,
  `ProjectID` int(11) DEFAULT NULL,
  `MaterialName` varchar(200) NOT NULL,
  `Cost` float NOT NULL,
  `Quantity` int(11) NOT NULL,
  `Supplier` varchar(200) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `payment`
--

CREATE TABLE `payment` (
  `PaymentID` int(11) NOT NULL,
  `ContractorID` int(11) DEFAULT NULL,
  `ProjectID` int(11) DEFAULT NULL,
  `Amount` float NOT NULL,
  `PaymentDate` datetime NOT NULL,
  `Method` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `project`
--

CREATE TABLE `project` (
  `ProjectID` int(11) NOT NULL,
  `ContractorID` int(11) DEFAULT NULL,
  `Name` varchar(150) NOT NULL,
  `Location` varchar(50) NOT NULL,
  `StartDate` date NOT NULL,
  `EndDate` date NOT NULL,
  `Budget` float NOT NULL
) ;

--
-- Dumping data for table `project`
--

INSERT INTO `project` (`ProjectID`, `ContractorID`, `Name`, `Location`, `StartDate`, `EndDate`, `Budget`) VALUES
(1, 1, 'kigali green Project', 'kigali CBD', '2024-01-01', '2027-12-31', 30),
(2, 1, 'Akanyaru Multipurpose Dam', 'Akanyaru river', '2022-01-01', '2025-12-31', 44),
(3, 2, 'Rusumo HydroElectric power station', 'Rusumo falls', '2017-01-01', '2030-12-31', 100),
(4, 2, 'Kigali Innovation City (KIC)', 'Special Economic Zone', '2025-12-01', '2030-12-31', 27),
(5, 3, 'Kigali Urban Transport Improvement project(KUTI)', 'Kigali', '2025-01-01', '2030-10-31', 60);

-- --------------------------------------------------------

--
-- Stand-in structure for view `total_payment`
-- (See below for the actual view)
--
CREATE TABLE `total_payment` (
`ProjectID` int(11)
,`ContractorID` int(11)
,`Name` varchar(150)
,`Location` varchar(50)
,`StartDate` date
,`EndDate` date
,`Budget` float
);

-- --------------------------------------------------------

--
-- Structure for view `total_payment`
--
DROP TABLE IF EXISTS `total_payment`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `total_payment`  AS SELECT `project`.`ProjectID` AS `ProjectID`, `project`.`ContractorID` AS `ContractorID`, `project`.`Name` AS `Name`, `project`.`Location` AS `Location`, `project`.`StartDate` AS `StartDate`, `project`.`EndDate` AS `EndDate`, `project`.`Budget` AS `Budget` FROM `project` GROUP BY `project`.`ContractorID` ;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `contractor`
--
ALTER TABLE `contractor`
  ADD PRIMARY KEY (`ContractorID`);

--
-- Indexes for table `equipment`
--
ALTER TABLE `equipment`
  ADD PRIMARY KEY (`EquipmentID`),
  ADD KEY `ProjectID` (`ProjectID`);

--
-- Indexes for table `expense`
--
ALTER TABLE `expense`
  ADD PRIMARY KEY (`ExpenseID`),
  ADD KEY `ProjectID` (`ProjectID`);

--
-- Indexes for table `material`
--
ALTER TABLE `material`
  ADD PRIMARY KEY (`MaterialID`),
  ADD KEY `ProjectID` (`ProjectID`);

--
-- Indexes for table `payment`
--
ALTER TABLE `payment`
  ADD PRIMARY KEY (`PaymentID`),
  ADD KEY `ProjectID` (`ProjectID`),
  ADD KEY `ContractorID` (`ContractorID`);

--
-- Indexes for table `project`
--
ALTER TABLE `project`
  ADD PRIMARY KEY (`ProjectID`),
  ADD KEY `project_ibfk_1` (`ContractorID`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `contractor`
--
ALTER TABLE `contractor`
  MODIFY `ContractorID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `equipment`
--
ALTER TABLE `equipment`
  MODIFY `EquipmentID` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `expense`
--
ALTER TABLE `expense`
  MODIFY `ExpenseID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `material`
--
ALTER TABLE `material`
  MODIFY `MaterialID` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `payment`
--
ALTER TABLE `payment`
  MODIFY `PaymentID` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `project`
--
ALTER TABLE `project`
  MODIFY `ProjectID` int(11) NOT NULL AUTO_INCREMENT;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `equipment`
--
ALTER TABLE `equipment`
  ADD CONSTRAINT `equipment_ibfk_1` FOREIGN KEY (`ProjectID`) REFERENCES `project` (`ProjectID`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `expense`
--
ALTER TABLE `expense`
  ADD CONSTRAINT `expense_ibfk_1` FOREIGN KEY (`ProjectID`) REFERENCES `project` (`ProjectID`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `material`
--
ALTER TABLE `material`
  ADD CONSTRAINT `material_ibfk_1` FOREIGN KEY (`ProjectID`) REFERENCES `project` (`ProjectID`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `payment`
--
ALTER TABLE `payment`
  ADD CONSTRAINT `payment_ibfk_1` FOREIGN KEY (`ProjectID`) REFERENCES `project` (`ProjectID`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `payment_ibfk_2` FOREIGN KEY (`ContractorID`) REFERENCES `contractor` (`ContractorID`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `project`
--
ALTER TABLE `project`
  ADD CONSTRAINT `project_ibfk_1` FOREIGN KEY (`ContractorID`) REFERENCES `contractor` (`ContractorID`) ON DELETE CASCADE ON UPDATE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
