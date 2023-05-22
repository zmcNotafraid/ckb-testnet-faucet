import React from "react";
import { Button, FormControl, Form, Col, Row, Alert } from "react-bootstrap";
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import { faCircleQuestion } from '@fortawesome/free-solid-svg-icons';
import Tooltip from 'react-bootstrap/Tooltip';
import OverlayTrigger from 'react-bootstrap/OverlayTrigger';

interface ClaimEventFormProps {
  addressHash: string,
  remaining: string | null;
  handleChange: React.ChangeEventHandler<HTMLInputElement>;
  handleInput: React.ChangeEventHandler<HTMLInputElement>;
  handleSubmit: React.FormEventHandler<HTMLFormElement>;
  formError: string | null;
}

const ClaimEventForm: React.FC<ClaimEventFormProps> = ({
  addressHash,
  remaining,
  handleChange,
  handleInput,
  handleSubmit,
  formError
}) => {
  return (
    <Form noValidate onSubmit={handleSubmit}>
      <Form.Group as={Row} className="mb-3">
        <Col sm={{ span: 10, offset: 1 }}>
          {
            formError &&
            <Alert key="danger" variant="danger">
              {formError}
            </Alert>
          }
        </Col>
      </Form.Group>

      <Form.Group as={Row} className="mb-3" controlId="formHorizontalEmail">
        <Form.Label column sm={{ span: 2, offset: 1 }}>
          To Address
        </Form.Label>
        <Col sm="8">
          <FormControl
            placeholder="Enter your Pudge wallet address"
            aria-label="Pudge address"
            aria-describedby="Enter your Pudge wallet address"
            name="address_hash"
            value={addressHash}
            onChange={handleInput}
            className={formError !== "" ? "is-invalid" : ""}
            autoFocus
          />
        </Col>
      </Form.Group>

      <Form.Group as={Row} className="mb-3">
        <Form.Label column sm={{ span: 2, offset: 1 }}>
          Amount
        </Form.Label>
        <Col sm="4" className="align-self-center">
          <Form.Check
            inline
            label="10,000"
            name="amount"
            type="radio"
            value="10000"
            onChange={handleChange}
            id={`ten_thousand_radio`}
          />
          <Form.Check
            inline
            label="100,000"
            value="100000"
            name="amount"
            type="radio"
            onChange={handleChange}
            id={`one_hundred_thousand_radio`}
          />
          <Form.Check
            inline
            label="300,000"
            value="300000"
            name="amount"
            type="radio"
            onChange={handleChange}
            id={`three_hundred_thousand_radio`}
          />
        </Col>

        <Col sm="4" className="align-self-center" >
          <div id="remaining-text"> Remaining: {" "}
            {remaining != null && Number(remaining).toLocaleString("en")}
            &nbsp; CKB &nbsp;
            <OverlayTrigger
              overlay={
                <Tooltip id="remaining-tooltip">
                  Your claimable amount now for this month is {remaining != null && Number(remaining).toLocaleString("en")} CKB.
                </Tooltip>
              }
            >
              <FontAwesomeIcon icon={faCircleQuestion} />
            </OverlayTrigger>
          </div>
        </Col>
      </Form.Group>

      <Form.Group as={Row} className="mb-3">
        <Col sm={{ span: 7, offset: 5 }}>
          <Button variant="primary" type="submit" id="claim_button">Claim</Button>
        </Col>
      </Form.Group>
    </Form >
  );
};

export default ClaimEventForm;
